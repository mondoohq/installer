# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# The POSIX test of the set. Every other stage reaches its shell through
# install.sh's #!/bin/sh shebang, and which shell that is belongs to the
# distribution rather than to us:
#
#   debian, ubuntu                    /bin/sh -> dash
#   almalinux, opensuse, amazonlinux  /bin/sh -> bash
#
# So the dash coverage is real but inherited, and it would disappear silently
# if a distribution repointed /bin/sh or if the shebang were ever edited --
# every job would stay green while nothing tested POSIX any more.
#
# dash is named here so that cannot happen. It matters because the static gate
# does not catch everything a runtime does: `dash -n` parses $'\n' happily,
# treating it as a literal $ followed by a quoted string, so only checkbashisms
# stands between that particular bashism and a release. This stage is the
# second line.
#
# The same gap shipped in download.sh -- see mondoohq/installer#813 and #805.

FROM debian:12 AS dash
RUN apt-get update -qq && apt-get install -y -qq curl dash ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*
COPY install.sh /run/install.sh
RUN dash /run/install.sh
RUN cnspec version
