#!/bin/sh -e
# Copyright Mondoo, Inc. 2026, 2025, 0
# SPDX-License-Identifier: BUSL-1.1

printf "\033[0;31mThe mondoo command is now cnspec, the cloud-native specification & security scanner. Please call the cnspec binary directly. Support for invoking cnspec by calling mondoo will be removed in a future version.\033[0m\n"
cnspec "$@"
