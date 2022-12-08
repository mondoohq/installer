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

MONDOO_PRODUCT_NAME="Mondoo Client" # product name
MONDOO_PKG_NAME="mondoo" # pkg name in package repository
MONDOO_BINARY="mondoo" # binary that we search for

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
  red "The ${MONDOO_PRODUCT_NAME} install script encountered a problem. For assistance, please join our community on GitHub Discussions."
  echo
  echo "* Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions"
  echo
  echo "* GitHub: https://github.com/mondoohq/client"
  echo
  exit 1
}

# register a trap for error signals
trap on_error ERR

purple_bold "${MONDOO_PRODUCT_NAME} Installer"
purple "
                        .-.
                        : :
,-.,-.,-. .--. ,-.,-. .-' : .--.  .--. ™
: ,. ,. :' .; :: ,. :' .; :' .; :' .; :
:_;:_;:_;\`.__.':_;:_;\`.__.'\`.__.'\`.__.
"

echo -e "\nWelcome to the ${MONDOO_PRODUCT_NAME} installer. We will auto-detect
your operating system to determine the best installation method.
If you experience any issues, please reach us at:

  * Mondoo Community GitHub Discussions:
    https://github.com/orgs/mondoohq/discussions

This installer is licensed under the Apache License, Version 2.0

  * GitHub:
  https://github.com/mondoohq/client

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
MONDOO_BINARY_PATH="${MONDOO_BINARY}" # default expects the binary in default path
MONDOO_EXECUTABLE=""
MONDOO_INSTALLED=false
detect_mondoo() {
  MONDOO_EXECUTABLE="$(command -v "$MONDOO_BINARY")"
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
  if [ -x "${MONDOO_BINARY}" ]; then
    MONDOO_EXECUTABLE="$(pwd)/${MONDOO_BINARY}"
    MONDOO_BINARY_PATH="./${MONDOO_BINARY}"
    MONDOO_INSTALLED=true
  fi
}

detect_latest_version() {
  MONDOO_LATEST_VERSION="$(curl https://releases.mondoo.com/${MONDOO_PKG_NAME}/ 2>/dev/null | grep -Eo 'href="[[:alnum:]]+\.[[:alnum:]]+\.[[:alnum:]]+' | head -n1 | sed 's/href="//')"
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
    red "${MONDOO_PRODUCT_NAME} does not support the (${ARCH_DETECT}) architecture."
    exit 1
    ;;
  esac

  detect_latest_version

  FILE="${MONDOO_BINARY}_${MONDOO_LATEST_VERSION}_${SYSTEM}_${ARCH}.tar.gz"
  URL="https://releases.mondoo.com/${MONDOO_BINARY}/${MONDOO_LATEST_VERSION}/${FILE}"

  echo "Downloading the latest version of ${MONDOO_PRODUCT_NAME} from: $URL"
  curl "${URL}" | tar xz

  detect_portable
  if [ -z "$MONDOO_EXECUTABLE" ]; then
    red "We could not find the '${MONDOO_BINARY}' executable in the present working directory."
    exit 1
  fi

  purple_bold "We installed a portable version of ${MONDOO_BINARY} to $PWD"
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
      purple_bold "\n* Configuring brew sources for Mondoo Repository via 'brew tap'"
      brew tap mondoohq/mondoo

      purple_bold "\n* Installing ${MONDOO_PRODUCT_NAME} via 'brew install'"
      brew install ${MONDOO_PKG_NAME}
    }

    mondoo_update() {
      purple_bold "\n* Upgrade ${MONDOO_PRODUCT_NAME} via 'brew upgrade'"
      if brew tap | grep mondoolabs/mondoo >/dev/null; then
        purple_bold "  - Legacy tap already exists, uninstalling Mondoo and re-installing from new tap"
        brew uninstall ${MONDOO_PKG_NAME} && brew untap mondoolabs/mondoo
        brew tap mondoohq/mondoo && brew install ${MONDOO_PKG_NAME}
      else
        brew upgrade ${MONDOO_PKG_NAME}
      fi
    }

  else
    MONDOO_INSTALLER="pkg"
    mondoo_install() {
      detect_latest_version
      FILE="${MONDOO_BINARY}_${MONDOO_LATEST_VERSION}_darwin_universal.pkg"
      URL="https://releases.mondoo.com/${MONDOO_BINARY}/${MONDOO_LATEST_VERSION}/${FILE}"

      purple_bold "\n* Downloading ${MONDOO_PRODUCT_NAME} Universal Package for Mac"
      curl -sO "${URL}"

      purple_bold "\n* Installing ${MONDOO_PRODUCT_NAME} via 'installer -pkg'"
      sudo_cmd /usr/sbin/installer -pkg "${FILE}" -target /

      purple_bold "\n* Cleaning up downloaded package"
      rm "${FILE}"
    }
    mondoo_update() { mondoo_install "$@"; }
  fi
}

# Arch Linux installer
# --------------------

configure_archlinux_installer() {
  if [ -x "$(command -v yay)" ]; then
    MONDOO_INSTALLER="yay"
    mondoo_install() {
      yay -S "${MONDOO_PKG_NAME}"
    }
    mondoo_update() { mondoo_install "$@"; }

  elif [ -x "$(command -v paru)" ]; then
    MONDOO_INSTALLER="paru"
    mondoo_install() {
      paru -S "${MONDOO_PKG_NAME}"
    }
    mondoo_update() { mondoo_install "$@"; }

  else
    MONDOO_INSTALLER=""
    mondoo_install() {
      red "Mondoo uses yay and paru to install on AUR, but we could not find either command in your path (\$PATH)."
      echo "You can install the ${MONDOO_PRODUCT_NAME} package manually from AUR, or use one of the above installers directly."
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

      purple_bold "\n* Installing ${MONDOO_PRODUCT_NAME}"
      sudo_cmd yum install -y ${MONDOO_PKG_NAME}
    }

    mondoo_update() {
      sudo_cmd yum update -y ${MONDOO_PKG_NAME}
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
      APT_VERSION=$(dpkg-query --show --showformat '${Version}' apt)
      if dpkg --compare-versions "${APT_VERSION}" le 1.0.2;
      then
        curl --retry 3 --retry-delay 10 -sSL https://releases.mondoo.com/debian/pubkey.gpg | sudo_cmd apt-key add -
        echo "deb https://releases.mondoo.com/debian/ stable main" | sudo_cmd tee /etc/apt/sources.list.d/mondoo.list
      else
        curl --retry 3 --retry-delay 10 -sSL https://releases.mondoo.com/debian/pubkey.gpg | sudo_cmd gpg --dearmor --output /usr/share/keyrings/mondoo-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/mondoo-archive-keyring.gpg] https://releases.mondoo.com/debian/ stable main" | sudo_cmd tee /etc/apt/sources.list.d/mondoo.list
      fi


      purple_bold "\n* Installing ${MONDOO_PRODUCT_NAME}"
      sudo_cmd apt update -y && sudo_cmd apt install -y ${MONDOO_PKG_NAME}
    }

    mondoo_update() {
      sudo_cmd apt update -y && sudo_cmd apt --only-upgrade install -y ${MONDOO_PKG_NAME}
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

      purple_bold "\n* Installing ${MONDOO_PRODUCT_NAME}"
      sudo_cmd zypper -n install ${MONDOO_PKG_NAME}
    }

    mondoo_update() {
      sudo_cmd zypper -n update ${MONDOO_PKG_NAME}
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
    purple_bold "\n* Installing ${MONDOO_PRODUCT_NAME} to $install_dir"
    mkdir -p "$install_dir"
    (cd "${install_dir}" || exit 1; install_portable)
    PATH="$PATH:$install_dir"
  }

  mondoo_update() {
    mondoo_install
  }

  configure_linux_token() {
    purple_bold "\n* Register ${MONDOO_PRODUCT_NAME} with Mondoo Platform"
    config_path="$HOME/.config/mondoo"
    mkdir -p "$config_path"
    ${MONDOO_BINARY_PATH} register --config "$config_path/mondoo.yml" --token "$MONDOO_REGISTRATION_TOKEN"
  }
}

# Post-install actions
# --------------------

detect_mondoo_registered() {
  if [ "$(
    ${MONDOO_BINARY_PATH} status >/dev/null 2>&1
    echo $?
  )" -eq "0" ]; then
    MONDOO_IS_REGISTERED=true
  else
    MONDOO_IS_REGISTERED=false
  fi
}

configure_token() {
  if [ -z "${MONDOO_REGISTRATION_TOKEN}" ]; then
    if [ "$MONDOO_PRODUCT_NAME" = "Mondoo Client" ]; then
      echo -e "\n* No registration token provided, skipping ${MONDOO_PRODUCT_NAME} registration."
    fi
    return
  else
    purple_bold "\n* Registration token detected, checking if ${MONDOO_PRODUCT_NAME} is registered..."
  fi

  detect_mondoo_registered
  if [ $MONDOO_IS_REGISTERED = true ]; then
    purple_bold "\n* ${MONDOO_PRODUCT_NAME} is already registered. Skipping registration"
    purple_bold "(you can manually run '${MONDOO_BINARY} register' to re-register)."
    return
  fi

  if [ $OS = "macOS" ]; then
    configure_macos_token
  else
    configure_linux_token
  fi

  detect_mondoo_registered
  if [ $MONDOO_IS_REGISTERED = true ]; then
    purple_bold "\n* ${MONDOO_PRODUCT_NAME} was successfully registered."
  else
    red "\n* Failed to register ${MONDOO_PRODUCT_NAME}. Please reach out in the Mondoo Community GitHub Discussions - https://github.com/orgs/mondoohq/discussions."
    exit 1
  fi
}

configure_macos_token() {
  purple_bold "\n* Register ${MONDOO_PRODUCT_NAME} with Mondoo Platform"
  config_path="$HOME/.config/mondoo"
  mkdir -p "$config_path"
  ${MONDOO_BINARY_PATH} register --config "$config_path/mondoo.yml" --token "$MONDOO_REGISTRATION_TOKEN"
}

configure_linux_token() {
  purple_bold "\n* Register ${MONDOO_PRODUCT_NAME} with Mondoo Platform"
  sudo_cmd mkdir -p "/etc/opt/mondoo/"
  sudo_cmd ${MONDOO_BINARY_PATH} register --config /etc/opt/mondoo/mondoo.yml --token "$MONDOO_REGISTRATION_TOKEN"

  if [ "$(cat /proc/1/comm)" = "init" ]; then
    purple_bold "\n* Restart upstart service"
    sudo_cmd stop mondoo || true
    sudo_cmd start mondoo || true
  elif [ "$(cat /proc/1/comm)" = "systemd" ]; then
    purple_bold "\n* Restart systemd service"
    sudo_cmd systemctl restart mondoo.service
  else
    red "\nWe could not detect your process supervisor. If ${MONDOO_PRODUCT_NAME} is running as a service, you will need to restart it manually to make sure it is registered."
  fi
}

postinstall_check() {
  detect_mondoo
  if [ $MONDOO_INSTALLED = false ]; then
    red "${MONDOO_PRODUCT_NAME} installation failed (can't find the ${MONDOO_BINARY} binary)."
    exit 1
  fi

  echo "${MONDOO_PRODUCT_NAME} installation completed."
}

finalize_setup() {

  # If registration token is provided, register client
  configure_token

  # Display final message
  purple_bold "\n${MONDOO_PRODUCT_NAME} is ready to go!"

  # Only if installing Mondoo Client, warn user to register. Do not warn open source users.
  if [ "$MONDOO_PRODUCT_NAME" = "Mondoo Client" ]; then
    detect_mondoo_registered
    if [ $MONDOO_IS_REGISTERED = false ]; then
      echo
      lightblue_bold "Next you should register ${MONDOO_PRODUCT_NAME} to get access to policies and reports."
      lightblue_bold "Follow this guide: "
      echo
      lightblue_bold "https://mondoo.com/docs/operating_systems/installation/registration/"
      echo
    else
      echo
      lightblue_bold "Run 'mondoo scan local' to scan this system or learn more in our quick start docs: https://mondoo.com/docs/"
      echo
    fi
  else
    echo
    lightblue_bold "Run the following command to scan this system:"
    echo
    echo -e "${MONDOO_BINARY} scan"
    echo
    lightblue_bold "Learn more in our quick start guides: https://mondoo.com/docs/"
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
  purple_bold "\n* ${MONDOO_PRODUCT_NAME} is already installed. Updating Mondoo..."
  mondoo_update "$@";
  finalize_setup
  exit 0
fi

if [ -z "${MONDOO_INSTALLER}" ]; then
  red "Cannot determine which installer to use. Exiting."
  exit 1
fi
purple_bold "\n* Installing ${MONDOO_PRODUCT_NAME} via $MONDOO_INSTALLER"
mondoo_install

postinstall_check
finalize_setup
