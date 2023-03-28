#!/bin/sh -e
printf "\033[0;31mThe mondoo command is now cnspec, the cloud-native specification & security scanner. Please call the cnspec binary directly. Support for invoking cnspec by calling mondoo will be removed in a future version.\033[0m\n"
cnspec "$@"
