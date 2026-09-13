#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Test that install.sh completes on a host whose ONLY route off the machine is
# an HTTP proxy given with -x.
#
# This needs real network isolation, which is the whole point: every other
# install.sh test runs on a runner with direct egress, so a proxy bug is
# invisible to them. An https-only proxy export, for instance, leaves
# `apt update` unable to reach deb.debian.org -- and the packages install.sh
# bootstraps from there (curl, gnupg, ca-certificates) then cannot be fetched,
# so the run dies before it reaches Mondoo's own repository.
#
# Needs docker. Not part of `make test/install_sh/all`.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="${SCRIPT_DIR}/../../install.sh"

# Pinned by digest, the way the workflows pin their actions: a moving tag can
# change squid's behaviour or break the config under us, and a proxy test that
# fails for an unrelated upstream reason is worse than no proxy test.
SQUID_IMAGE="ubuntu/squid@sha256:6a097f68bae708cedbabd6188d68c7e2e7a38cedd05a176e1cc0ba29e3bbe029"  # 24.04, Squid 6.13
CURL_IMAGE="curlimages/curl@sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13"
DEBIAN_IMAGE="debian:12"

NET_INT="mondoo-proxy-test-internal"
NET_EXT="mondoo-proxy-test-external"
SQUID="mondoo-proxy-test-squid"

PASS=0
FAIL=0
TESTS=0

cleanup() {
  docker rm -f "$SQUID" >/dev/null 2>&1 || true
  docker network rm "$NET_INT" >/dev/null 2>&1 || true
  docker network rm "$NET_EXT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

assert() {
  TESTS=$((TESTS + 1))
  _label="$1"; _got="$2"; _want="$3"
  if [ "$_got" = "$_want" ]; then
    PASS=$((PASS + 1))
    printf '  ok    %s\n' "$_label"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL  %s\n        expected %s, got %s\n' "$_label" "$_want" "$_got" >&2
  fi
}

printf '==> Testing install.sh behind an HTTP proxy\n\n'

cleanup
docker network create "$NET_EXT" >/dev/null
# --internal is what makes this a real test: containers on this network have no
# route off the host at all, so anything that succeeds did so through the proxy.
docker network create --internal "$NET_INT" >/dev/null

# The config is written inside the container rather than bind-mounted: a host
# temp directory is not shareable on every Docker host (Docker Desktop refuses
# paths outside its file sharing list), and this keeps the test self-contained.
# --entrypoint: the image's entrypoint is squid itself, so without this the
# shell command below is handed to squid as arguments.
docker run -d --name "$SQUID" --network "$NET_EXT" --entrypoint sh "$SQUID_IMAGE" -c '
  cat > /etc/squid/squid.conf <<SQUIDCONF
http_port 3128
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl CONNECT method CONNECT
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow all
coredump_dir /var/spool/squid
SQUIDCONF
  exec squid -N -d1
' >/dev/null
docker network connect "$NET_INT" "$SQUID"

# Wait for squid rather than sleeping a guessed interval.
_ready=0
_i=0
while [ "$_i" -lt 30 ]; do
  if docker run --rm --network "$NET_INT" "$CURL_IMAGE" \
       -s -o /dev/null --max-time 5 -x "http://${SQUID}:3128" \
       https://releases.mondoo.com/mondoo/latest.json 2>/dev/null; then
    _ready=1
    break
  fi
  # If squid died there is nothing to wait for, and spinning the full minute
  # buries the reason. Say so and stop.
  if [ "$(docker inspect --format '{{.State.Running}}' "$SQUID" 2>/dev/null)" != "true" ]; then
    printf '\nsquid exited before it was ready:\n' >&2
    docker logs "$SQUID" 2>&1 | tail -5 >&2
    break
  fi
  _i=$((_i + 1))
  sleep 2
done
assert "the proxy reaches releases.mondoo.com" "$_ready" "1"

# Control. If this ever succeeds the isolation is broken and every result
# below is meaningless, because the container could have gone direct.
if docker run --rm --network "$NET_INT" "$CURL_IMAGE" \
     -s -o /dev/null --max-time 8 https://releases.mondoo.com/mondoo/latest.json 2>/dev/null; then
  _direct=1
else
  _direct=0
fi
assert "no direct egress without the proxy" "$_direct" "0"

# The real case: a host with nothing preinstalled, reachable only via -x.
# install.sh has to bootstrap curl/gnupg/ca-certificates over plain http from
# the distribution's repositories, then fetch Mondoo's packages over https.
# run_install prints install.sh's own output followed by a ::<rc> marker, so a
# failure here shows why rather than only that. The log lives in the container,
# which is gone by the time the assertion runs.
run_install() {
  docker run --rm --network "$NET_INT" "$@" \
    -v "${INSTALL_SH}:/run/install.sh:ro" "$DEBIAN_IMAGE" \
    sh -c "${_install_cmd} >/tmp/out 2>&1; _rc=\$?; cnspec version >/dev/null 2>&1 || _rc=1; cat /tmp/out; printf '::%s' \"\$_rc\"" 2>&1
}

report_failure() {
  printf '\n%s\n' "$1" >&2
  printf '%s\n' "${2%::*}" | tail -20 >&2
}

_install_cmd="sh /run/install.sh -x http://${SQUID}:3128"
_out=$(run_install)
_rc="${_out##*::}"
[ "$_rc" = "0" ] || report_failure "install.sh -x output:" "$_out"
assert "install.sh completes with -x on a bare host" "$_rc" "0"

# And the same through an inherited proxy environment rather than the flag.
_install_cmd="sh /run/install.sh"
_out=$(run_install -e "https_proxy=http://${SQUID}:3128" -e "http_proxy=http://${SQUID}:3128")
_rc="${_out##*::}"
[ "$_rc" = "0" ] || report_failure "install.sh inherited-proxy output:" "$_out"
assert "install.sh completes with an inherited proxy" "$_rc" "0"

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
