#!/bin/bash
#
# Copyright (c) 2019-2025 Mondoo, Inc.
# License: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Automatic Mondoo downloader to be used with
# curl -sSL https://mondoo.com/download.sh | sh -
#
# This script requires tar and gzip as helper commands
# e.g. yum install tar gzip

# Any subsequent commands which fails will stop the execution of the shell script
set -e

# define colors
end="\033[0m"
red="\033[0;31m"
redb="\033[1;31m"
purple="\033[0;35m"
purpleb="\033[1;35m"

purple() { echo -e "${purple}${1}${end}"; }
purple_bold() { echo -e "${purpleb}${1}${end}"; }
red() { echo -e "${red}${1}${end}"; }
red_bold() { echo -e "${redb}${1}${end}"; }

purple_bold "Mondoo Binary Download Script"
purple "
                        .-.
                        : :
,-.,-.,-. .--. ,-.,-. .-' : .--.  .--. ™
: ,. ,. :' .; :: ,. :' .; :' .; :' .; :
:_;:_;:_;\`.__.':_;:_;\`.__.'\`.__.'\`.__.
"

echo -e "\nWelcome to the Mondoo Binary Download Script. It tries to auto-detect your
operating system and determines the appropriate binary for your platform. If you are
experiencing any issues, please do not hesitate to reach out:

  * Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions

This script source is available at: https://github.com/mondoohq/installer
"

base_url="${MONDOO_MIRROR:-https://install.mondoo.com/package}"
product="${MONDOO_PRODUCT:-cnspec}"
version="${MONDOO_VERSION:-latest}"
channel="${MONDOO_CHANNEL:-}"

fail() {
  echo -e "${red}${1}${end}";
    exit 1;
}

arch=""
case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    i386)    arch="386" ;;
    i686)    arch="386" ;;
    arm)     arch="arm" ;;
    aarch64) arch="arm64";;
    arm64)   arch="arm64";;
    s390x)   arch="s390x";;
    *)       fail "Cannot detect architecture" ;;
esac

os=""
case "$(uname -s)" in
    Linux)  os="linux" ;;
    Darwin) os="darwin" ;;
    DragonFly) os="dragonfly" ;;
    GNU/kFreeBSD) os="freebsd" ;;
    FreeBSD) os="freebsd" ;;
    OpenBSD) os="openbsd" ;;
    SunOS) os="solaris" ;;
    NetBSD) os="netbsd" ;;
    *)      fail "Cannot detect OS" ;;
esac

# determine sha tool based on os
if [ $os = "darwin" ]; then
  sha256bin='shasum -a 256'
else
  sha256bin=sha256sum
fi

# Everything this script cannot work without. Checked together so a bare
# container is told the whole list at once rather than discovering it one
# failed run at a time, and checked here because the sha tool depends on the
# OS detected above.
missing=""
for cmd in curl tar gzip "${sha256bin%% *}"; do
  command -v "${cmd}" >/dev/null 2>&1 || missing="${missing} ${cmd}"
done
if [ -n "${missing}" ]; then
  fail "This script needs the following commands, which are not in your \$PATH:${missing}"
fi

filename="${product}_${version}_${os}_${arch}.tar.gz"
pkg_base_url="${base_url}/${product}/${os}/${arch}/tar.gz/${version}"

# The channel selects which release line `latest` resolves to. It is only
# meaningful for a moving version: a pinned MONDOO_VERSION names one build, and
# that build is the same object whichever channel points at it.
#
# Appended only when asked for, so the default URLs -- and the cache entries
# keyed on them -- are unchanged.
channel_query=""
if [ -n "${channel}" ]; then
  case "${channel}" in
    stable|preview) ;;
    *) fail "Unknown channel '${channel}', expected stable or preview." ;;
  esac
  if [ "${version}" != "latest" ]; then
    purple "Ignoring MONDOO_CHANNEL=${channel}: MONDOO_VERSION=${version} already names a build."
  else
    channel_query="?channel=${channel}"
  fi
fi

download_url="${pkg_base_url}/download${channel_query}"
sha_url="${pkg_base_url}/sha256${channel_query}"

UserAgent="MondooDownloadScript/1.0 (+https://mondoo.com/) ShellScript/$BASH_VERSION ($OS $DISTRIBUTION)"

# download the checksum first. It is a few bytes, and a 404 here means the
# package index has nothing for this platform/arch, which is worth reporting
# before we start writing a tarball to disk.
purple_bold "Downloading ${sha_url}"
# Three outcomes worth telling apart, because they send the reader somewhere
# different: the request never completed, the server said the package is not
# there, or the server failed. Dropping -f is what makes that possible -- with
# it, curl exits 22 for every status >= 400 and 404 is indistinguishable from
# 503, so a release server having a bad day reads as "your platform is not
# supported".
sha_rc=0
sha_response=$(curl -sSL -w '\n%{http_code}' "${sha_url}") || sha_rc=$?
if [ "${sha_rc}" -ne 0 ]; then
  fail "Could not reach ${sha_url} (curl exit ${sha_rc}).\nCheck your network or proxy settings."
fi

sha_code="${sha_response##*$'\n'}"
expectedSha="${sha_response%$'\n'*}"
case "${sha_code}" in
  200) ;;
  404) fail "No ${product} package for ${os}/${arch} (version ${version}).\nLooked in ${pkg_base_url}" ;;
  *)   fail "The release server returned HTTP ${sha_code} for ${sha_url}.\nThis is usually temporary -- try again shortly." ;;
esac
echo -e "Expected binary hash: ${expectedSha}"

# download binary
purple_bold "Downloading ${download_url}"
binarySha=$(curl -A "${UserAgent}" -fsSL "${download_url}" | tee "${filename}" | ${sha256bin} | cut -b 1-64)
echo -e "Downloaded binary hash: ${binarySha}"

# extract binary
if [ "$binarySha" = "$expectedSha" ]; then
  purple "Download matches the expected hash ${binarySha}"
  tar -xf "${filename}"
  chmod +x "${product}"
    rm "${filename}"
  purple "Installed to $(pwd)/${product}"
else
  # clean up on error
  rm "${filename}"
  fail "Binary hash '${binarySha}' does not match the expected hash '${expectedSha}'\nAborted download.";
fi

# Display final message
purple_bold "\nThank you for downloading Mondoo!"
echo -e "
You can register the client via:

MONDOO_REGISTRATION_TOKEN=\"ey..iU\"
mondoo register --token \$MONDOO_REGISTRATION_TOKEN

Further information is available at https://mondoo.com/docs/

If you have any questions, please come join us in our Mondoo Community:

* Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions
* GitHub: https://github.com/mondoohq/
"
