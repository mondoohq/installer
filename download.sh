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

filename="${product}_${version}_${os}_${arch}.tar.gz"
pkg_base_url="${base_url}/${product}/${os}/${arch}/tar.gz/${version}"
download_url="${pkg_base_url}/download"
sha_url="${pkg_base_url}/sha256"

UserAgent="MondooDownloadScript/1.0 (+https://mondoo.com/) ShellScript/$BASH_VERSION ($OS $DISTRIBUTION)"

# download binary
purple_bold "Downloading ${download_url}"
binarySha=$(curl -A "${UserAgent}" -fsSL "${download_url}" | tee "${filename}" | ${sha256bin} | cut -b 1-64)
echo -e "Downloaded binary hash: ${binarySha}"

# download the checksum
purple_bold "Downloading ${sha_url}"
expectedSha=$(curl -fsSL "${sha_url}")
echo -e "Expected binary hash: ${expectedSha}"

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
