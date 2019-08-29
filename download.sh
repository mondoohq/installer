#!/bin/sh
# Automatic Mondoo downloader to be used with
# curl -sSL https://mondoo.io/download.sh | sh -
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
  __  __                 _             
 |  \/  |               | |            
 | \  / | ___  _ __   __| | ___   ___  
 | |\/| |/ _ \| \_ \ / _\ |/ _ \ / _ \ 
 | |  | | (_) | | | | (_| | (_) | (_) |
 |_|  |_|\___/|_| |_|\__,_|\___/ \___/ 
"
                 
echo -e "\nWelcome to the Mondoo Binary Download Script. It tries to auto-detect your 
operating system and determines the appropriate binnary for your platform. If you are 
experiencing any issues, please do not hesitate to reach out: 

  * Mondoo Community https://spectrum.chat/mondoo

This script source is available at: https://github.com/mondoolabs/mondoo
"

base_url="${MONDOO_MIRROR:-https://releases.mondoo.io}"
product="mondoo"
version="${MONDOO_VERSION:-0.21.0}"

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

filename="${product}_${version}_${os}_${arch}.tar.gz"
url="${base_url}/${product}/${version}/${filename}"

if [ $os = "darwin" ]; then
  sha256bin='shasum -a 256'
else
  sha256bin=sha256sum
fi

purple_bold "Downloading ${url}"
binarySha=$(curl -fsSL ${url} | tee ${filename} | ${sha256bin} | cut -b 1-64)

# download the checksum
expectedSha=$(curl ${base_url}/${product}/${version}/checksums.txt | grep ${filename} | cut -b 1-64)

# extract binary
if [ $binarySha = $expectedSha ]; then
  purple "Download matches the exepected hash ${binarySha}"
  tar -xf ${filename}
  chmod +x "${product}"
	rm ${filename}
  purple "Installed to $(pwd)/${product}"
else
  # clean up on error
	rm ${filename}
  fail "Binary hash (${binarySha}) does not match the exepected hash ${expectedSha}\nAborted download.";
fi

if [ ! -z "${MONDOO_REGISTRATION_TOKEN}" ]
then
  purple_bold "Register agent with Mondoo Cloud"
  $(pwd)/mondoo register --token ${MONDOO_REGISTRATION_TOKEN}
else
  red "Skip agent registration since MONDOO_REGISTRATION_TOKEN was not set"
fi