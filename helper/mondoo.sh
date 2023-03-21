#!/bin/sh -e
printf "\033[0;31mMondoo command is deprecated. Use cnspec instead, Mondoo's cloud-native security scanner and CLI.\033[0m\n"
cnspec "$@"
