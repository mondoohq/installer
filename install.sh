#!/bin/bash
#
# Copyright (c) 2019-2022 Mondoo, Inc.
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
# The Mondoo installation script installs Mondoo on supported
# Linux distros using its native package manager
#
# The script may use the following environment variables:
#
# MONDOO_REGISTRATION_TOKEN
#     (Optional) Mondoo Registation Token. Systemd services
#     are only activated if Mondoo is properly authenticated.

# Please note that we aim to be POSIX-compatible in this script.
# If you find anything that violates this constraints please reach out.
# - https://unix.stackexchange.com/questions/73750/difference-between-function-foo-and-foo

# define colors
end="\033[0m"
red="\033[0;31m"
redb="\033[1;31m"
lightblue="\033[0;36m"
lightblueb="\033[1;36m"
green="\033[0;32m"
greenb="\033[1;32m"
purple="\033[0;35m"
purpleb="\033[1;35m"

red() { echo -e "${red}${1}${end}"; }
red_bold() { echo -e "${redb}${1}${end}"; }
green() { echo -e "${green}${1}${end}"; }
green_bold() { echo -e "${greenb}${1}${end}"; }
lightblue() { echo -e "${lightblue}${1}${end}"; }
lightblue_bold() { echo -e "${lightblueb}${1}${end}"; }
purple() { echo -e "${purple}${1}${end}"; }
purple_bold() { echo -e "${purpleb}${1}${end}"; }

on_error() {
  red "The Mondoo Client install script encountered a problem. For assistance, please join our community Slack or find us on GitHub."
  echo
  echo "* Mondoo Community Slack https://mondoo.link/slack"
  echo
  echo "* GitHub: https://github.com/mondoohq/client"
  echo
  exit 1
}

# register a trap for error signals
trap on_error ERR

purple_bold "Mondoo Client Installer"
purple "
                        .-.            
                        : :            
,-.,-.,-. .--. ,-.,-. .-' : .--.  .--. ™
: ,. ,. :' .; :: ,. :' .; :' .; :' .; :
:_;:_;:_;\`.__.':_;:_;\`.__.'\`.__.'\`.__.
"

echo -e "\nWelcome to the Mondoo Client installer. We will auto-detect 
your operating system to determine the best installation method.
If you experience any issues, please reach us at:

  * Mondoo Community Slack https://mondoo.link/slack

The source code of this installer is available on GitHub:

  * GitHub: https://github.com/mondoohq/client

"

# Detect operating system
# -----------------------
# Store detected value in $OS
KNOWN_DISTRIBUTION="(RedHat|Red Hat|CentOS|Debian|Ubuntu|openSUSE|Amazon|SUSE|Arch Linux|AlmaLinux|Rocky Linux)"
DISTRIBUTION="$(
  lsb_release -d 2>/dev/null | grep -Eo "$KNOWN_DISTRIBUTION" ||
    grep -m1 -Eo "$KNOWN_DISTRIBUTION" /etc/os-release 2>/dev/null ||
    grep -Eo "$KNOWN_DISTRIBUTION" /etc/issue 2>/dev/null ||
    uname -s
)"

if [ "$DISTRIBUTION" = "Darwin" ]; then
  OS="macOS"
elif [ -f /etc/debian_version ] || [ "$DISTRIBUTION" == "Debian" ] || [ "$DISTRIBUTION" == "Ubuntu" ]; then
  OS="Debian"
elif [ "$AWS_EXECUTION_ENV" == "CloudShell" ]; then
  OS="AWSCloudShell"
elif [ -f /etc/redhat-release ] || [ "$DISTRIBUTION" == "RedHat" ] || [ "$DISTRIBUTION" == "CentOS" ] || [ "$DISTRIBUTION" == "Amazon" ] || [ "$DISTRIBUTION" == "AlmaLinux" ] || [ "$DISTRIBUTION" == "Rocky Linux" ]; then
  OS="RedHat"
elif [ -f /etc/photon-release ] || [ "$DISTRIBUTION" == "Photon" ]; then
  # NOTE: it requires tdnf >= 2.1.2-3.ph3, before remote http gpg keys were not supported
  OS="RedHat"
# openSUSE and SUSE use /etc/SuSE-release
elif [ -f /etc/SuSE-release ] || [ "$DISTRIBUTION" == "SUSE" ] || [ "$DISTRIBUTION" == "openSUSE" ]; then
  OS="Suse"
elif [ -f /etc/arch-release ] || [ "$DISTRIBUTION" == "Arch" ]; then
  OS="Arch"
fi

# Installation detection
# ----------------------
# Note: https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
# To be POSIX-compatible we will be using 'command' instead of 'hash' or 'type'.
#

MONDOO_CMD="mondoo"
MONDOO_EXECUTABLE=""
MONDOO_INSTALLED=false
detect_mondoo() {
  MONDOO_EXECUTABLE="$(command -v mondoo)"
  if [ -x "$MONDOO_EXECUTABLE" ]; then
    MONDOO_INSTALLED=true
  else
    MONDOO_INSTALLED=false
  fi
}
# need to run this once initially
detect_mondoo

# Sudo command
# ------------
# Used for all privileged calls. If the script is run as root, this is not required.

if [ "$UID" = "0" ]; then
  sudo_cmd() {
    "$@"
  }
else
  sudo_cmd() {
    if [ -x "$(command -v sudo)" ]; then
      sudo "$@"
    else
      red "This command needs to run with elevated privileges, but we could not find the 'sudo' command in your path (\$PATH)."
      echo "The command we tried to run is: $*"
      exit 1
    fi
  }
fi

# Portable setup
# --------------

detect_portable() {
  if [ -x "mondoo" ]; then
    MONDOO_EXECUTABLE="$(pwd)/mondoo"
    MONDOO_CMD="./mondoo"
    MONDOO_INSTALLED=true
  fi
}

detect_latest_version() {
  MONDOO_LATEST_VERSION="$(curl https://releases.mondoo.com/mondoo/ 2>/dev/null | grep -Eo 'href="[[:alnum:]]+\.[[:alnum:]]+\.[[:alnum:]]+' | head -n1 | sed 's/href="//')"
}

install_portable() {
  FAIL=false
  if [ ! -x "$(command -v tar)" ]; then
    FAIL=true
    red "This script needs the 'tar' command, but we could not find 'tar' in your path (\$PATH)."
  fi
  if [ ! -x "$(command -v curl)" ]; then
    FAIL=true
    red "This script needs the 'curl' command, but we could not find 'curl' in your path (\$PATH)."
  fi
  if [ $FAIL = true ]; then exit 1; fi

  case "$OS" in
  "macOS") SYSTEM="darwin" ;;
  *) SYSTEM="linux" ;;
  esac

  ARCH_DETECT="$(uname -m)"
  case "$ARCH_DETECT" in
  "x86_64") ARCH="amd64" ;;
  "i386") ARCH="386" ;;
  "aarch64_be") ARCH="arm64" ;;
  "aarch64") ARCH="arm64" ;;
  "armv8b") ARCH="arm64" ;;
  "armv8l") ARCH="arm64" ;;
  *)
    red "Mondoo Client does not support the ($ARCH_DETECT) architecture."
    exit 1
    ;;
  esac

  detect_latest_version

  FILE="mondoo_${MONDOO_LATEST_VERSION}_${SYSTEM}_${ARCH}.tar.gz"
  URL="https://releases.mondoo.com/mondoo/${MONDOO_LATEST_VERSION}/${FILE}"

  echo "Downloading the latest version of Mondoo Client from: $URL"
  curl "${URL}" | tar xz

  detect_portable
  if [ -z "$MONDOO_EXECUTABLE" ]; then
    red "We could not find the 'mondoo' executable in the present working directory."
    exit 1
  fi

  purple_bold "We installed a portable version of mondoo to $PWD"
  if [[ ":$PATH:" == ":$PWD:" ]]; then
  purple_bold "For convenience, add the following line to your .bashrc"
  purple_bold "export PATH=\$PATH:$PWD"
  fi
}

# macOS installer
# ---------------

configure_macos_installer() {
  if [ -x "$(command -v brew)" ]; then
    MONDOO_INSTALLER="brew"
    mondoo_install() {
      purple_bold "\n* Configuring brew sources for Mondoo via 'brew tap'"
      brew tap mondoohq/mondoo

      purple_bold "\n* Installing Mondoo Client via 'brew install'"
      brew install mondoo
    }

    mondoo_update() {
      purple_bold "\n* Upgrade Mondoo Client via 'brew upgrade'"
      brew upgrade mondoo
    }

  else
    MONDOO_INSTALLER="pkg"
    mondoo_install() {
      detect_latest_version
      FILE="mondoo_${MONDOO_LATEST_VERSION}_darwin_universal.pkg"
      URL="https://releases.mondoo.com/mondoo/${MONDOO_LATEST_VERSION}/${FILE}"

      purple_bold "\n* Downloading Mondoo Client Universal Package for Mac" 
      curl -sO ${URL}

      purple_bold "\n* Installing Mondoo Client via 'installer -pkg'"
      sudo_cmd /usr/sbin/installer -pkg ${FILE} -target /
      
      purple_bold "\n* Cleaning up downloaded package"
      rm ${FILE}
    }
    mondoo_update() { mondoo_install "$@"; }
  fi
}

# Arch Linux installer
# --------------------

configure_archlinux_installer() {
  AUR_PACKAGE="mondoo"

  if [ -x "$(command -v yay)" ]; then
    MONDOO_INSTALLER="yay"
    mondoo_install() {
      yay -S "$AUR_PACKAGE"
    }
    mondoo_update() { mondoo_install "$@"; }

  elif [ -x "$(command -v paru)" ]; then
    MONDOO_INSTALLER="paru"
    mondoo_install() {
      paru -S "$AUR_PACKAGE"
    }
    mondoo_update() { mondoo_install "$@"; }

  else
    MONDOO_INSTALLER=""
    mondoo_install() {
      red "Mondoo uses yay and paru to install on AUR, but we could not find either command in your path (\$PATH)."
      echo "You can install the Mondoo package manually from AUR, or use one of the above installers directly."
      exit 1
    }
    mondoo_update() { mondoo_install "$@"; }
  fi
}

# RHEL installer
# --------------

configure_rhel_installer() {
  if [ -x "$(command -v yum)" ]; then
    MONDOO_INSTALLER="yum"
    mondoo_install() {
      purple_bold "\n* Configuring YUM sources for Mondoo at /etc/yum.repos.d/mondoo.repo"
      curl --retry 3 --retry-delay 10 -sSL https://releases.mondoo.com/rpm/mondoo.repo | sudo_cmd tee /etc/yum.repos.d/mondoo.repo

      purple_bold "\n* Installing Mondoo"
      sudo_cmd yum install -y mondoo
    }

    mondoo_update() {
      sudo_cmd yum update -y mondoo
    }

  else
    MONDOO_INSTALLER=""
    mondoo_install() {
      red "Mondoo uses YUM to install on Red Hat Linux, but we could not find the 'yum' command in your path (\$PATH)."
      exit 1
    }
    mondoo_update() { mondoo_install "$@"; }

  fi
}

# Debian installer
# ----------------

configure_debian_installer() {
  if [ -x "$(command -v apt)" ]; then
    MONDOO_INSTALLER="apt"
    mondoo_install() {
      purple_bold "\n* Installing prerequisites for Debian"
      sudo_cmd apt update -y
      sudo_cmd apt install -y apt-transport-https ca-certificates gnupg

      purple_bold "\n* Configuring APT package sources for Mondoo at /etc/apt/sources.list.d/mondoo.list"
      curl --retry 3 --retry-delay 10 -sSL https://releases.mondoo.com/debian/pubkey.gpg | sudo_cmd gpg --dearmor --output /usr/share/keyrings/mondoo-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/mondoo-archive-keyring.gpg] https://releases.mondoo.com/debian/ stable main" | sudo_cmd tee /etc/apt/sources.list.d/mondoo.list


      purple_bold "\n* Installing Mondoo"
      sudo_cmd apt update -y && sudo_cmd apt install -y mondoo
    }

    mondoo_update() {
      sudo_cmd apt update -y && sudo_cmd apt upgrade -y mondoo
    }

  else
    MONDOO_INSTALLER=""
    mondoo_install() {
      red "Mondoo uses APT to install on Debian Linux, but we could not find the 'apt' command in your path (\$PATH)."
      exit 1
    }
    mondoo_update() { mondoo_install "$@"; }

  fi
}

# SUSE installer
# --------------

configure_suse_installer() {
  if [ -x "$(command -v zypper)" ]; then
    MONDOO_INSTALLER="apt"
    mondoo_install() {
      purple_bold "\n* Configuring ZYPPER sources for Mondoo at /etc/zypp/repos.d/mondoo.repo"
      curl --retry 3 --retry-delay 10 -sSL https://releases.mondoo.com/rpm/mondoo.repo | sudo_cmd tee /etc/zypp/repos.d/mondoo.repo
      # zypper does not recognize the gpg key reference from mondoo.repo properly, therefore we need to add this here manually
      sudo_cmd rpm --import https://releases.mondoo.com/rpm/pubkey.gpg

      purple_bold "\n* Installing Mondoo"
      sudo_cmd zypper -n install mondoo
    }

    mondoo_update() {
      sudo_cmd zypper -n update mondoo
    }

  else
    MONDOO_INSTALLER=""
    mondoo_install() {
      red "Mondoo uses ZYPPER to install on SUSE Linux, but we could not find the 'zypper' command in your path (\$PATH)."
      exit 1
    }
    mondoo_update() { mondoo_install "$@"; }

  fi
}

# CloudShell installer
# --------------

configure_cloudshell_installer() {
  MONDOO_INSTALLER="tar"
  mondoo_install() {
    install_dir="$HOME/.local/bin"
    purple_bold "\n* Installing Mondoo Client to $install_dir"
    mkdir -p "$install_dir"
    (cd "$install_dir"; install_portable)
    PATH="$PATH:$install_dir"
  }

  mondoo_update() {
    mondoo_install
  }

  configure_linux_token() {
    purple_bold "\n* Register Mondoo Client with Mondoo Cloud"
    config_path="$HOME/.config/mondoo"
    mkdir -p "$config_path"
    ${MONDOO_CMD} register --config "$config_path/mondoo.yml" --token "$MONDOO_REGISTRATION_TOKEN"
  }
}

# Post-install actions
# --------------------

detect_mondoo_registered() {
  if [ "$(
    ${MONDOO_CMD} status >/dev/null 2>&1
    echo $?
  )" -eq "0" ]; then
    MONDOO_IS_REGISTERED=true
  else
    MONDOO_IS_REGISTERED=false
  fi
}

configure_token() {
  if [ -z "${MONDOO_REGISTRATION_TOKEN}" ]; then
    echo -e "\n* No registration token provided, skipping Mondoo Client registration."
    return
  fi

  purple_bold "\n* Registration token detected, checking if Mondoo Client is registered..."
  detect_mondoo_registered

  if [ $MONDOO_IS_REGISTERED = true ]; then
    purple_bold "\n* Mondoo Client is already registered. Skipping registration (you can manually run 'mondoo register' to re-register)."
    return
  fi

  if [ $OS = "macOS" ]; then
    configure_macos_token
  else
    configure_linux_token
  fi

  detect_mondoo_registered
  if [ $MONDOO_IS_REGISTERED = true ]; then
    purple_bold "\n* Mondoo Client was successfully registered."
  else
    red "\n* Failed to register Mondoo Client. Please reach out to us via Mondoo Community Slack - https://mondoo.link/slack."
    exit 1
  fi
}

configure_macos_token() {
  purple_bold "\n* Register Mondoo Client with Mondoo Cloud"
  config_path="$HOME/.config/mondoo"
  mkdir -p "$config_path"
  ${MONDOO_CMD} register --config "$config_path/mondoo.yml" --token "$MONDOO_REGISTRATION_TOKEN"
}

configure_linux_token() {
  purple_bold "\n* Register Mondoo Client with Mondoo Cloud"
  sudo_cmd mkdir -p "/etc/opt/mondoo/"
  sudo_cmd ${MONDOO_CMD} register --config /etc/opt/mondoo/mondoo.yml --token "$MONDOO_REGISTRATION_TOKEN"

  if [ "$(cat /proc/1/comm)" = "init" ]; then
    purple_bold "\n* Restart upstart service"
    sudo_cmd stop mondoo || true
    sudo_cmd start mondoo || true
  elif [ "$(cat /proc/1/comm)" = "systemd" ]; then
    purple_bold "\n* Restart systemd service"
    sudo_cmd systemctl restart mondoo.service
  else
    red "\nWe could not detect your process supervisor. If Mondoo Client is running as a service, you will need to restart it manually to make sure it is registered."
  fi
}

postinstall_check() {
  detect_mondoo
  if [ $MONDOO_INSTALLED = false ]; then
    red "Mondoo Client installation failed (can't find the Mondoo binary)."
    exit 1
  fi

  echo "Mondoo Client installation completed."
}

finalize_setup() {
  configure_token

  # Display final message
  detect_mondoo_registered
  if [ $MONDOO_IS_REGISTERED = false ]; then
    purple_bold "\nMondoo Client is ready to go!"
    echo
    lightblue_bold "Next you should register Mondoo Client to get access to policies and reports."
    lightblue_bold "Follow this guide: "
    echo
    lightblue_bold "https://mondoo.com/docs/operating_systems/installation/registration/"
    echo
  else
    purple_bold "\nMondoo Client is set up and ready to go!"
    echo
    lightblue_bold "Follow our quick start guide for next steps: https://mondoo.com/docs/"
    echo
  fi

}

# Determine which OS installer we are going to use
if [[ $OS = "macOS" ]]; then
  configure_macos_installer

elif [[ $OS = "Arch" ]]; then
  configure_archlinux_installer

elif [[ $OS = "RedHat" ]]; then
  configure_rhel_installer

elif [[ $OS = "Debian" ]]; then
  configure_debian_installer

elif [[ $OS = "Suse" ]]; then
  configure_suse_installer
elif [[ $OS = "AWSCloudShell" ]]; then
  configure_cloudshell_installer

else
  purple "Your operating system is not yet supported by this installer."
  exit 1
fi

# Mondoo installation / update
# ----------------------------

if [ $MONDOO_INSTALLED = true ]; then
  purple_bold "\n* Mondoo Client is already installed. Updating Mondoo..."
  mondoo_update "$@";
  finalize_setup
  exit 0
fi

if [ -z "${MONDOO_INSTALLER}" ]; then
  red "Cannot determine which installer to use. Exiting."
  exit 1
fi
purple_bold "\n* Installing Mondoo Client via $MONDOO_INSTALLER"
mondoo_install

postinstall_check
finalize_setup
