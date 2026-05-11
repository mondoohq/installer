#!/usr/bin/env bash
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1
#
# Wrapper script for running pytest-based tests.
# Creates/reuses a venv, installs pytest, and forwards arguments.
#
# Usage:
#   ./test/run_tests.sh [pytest args...]           # direct mode
#   ./test/run_tests.sh -i | --interactive         # interactive selector
#
# Examples:
#   ./test/run_tests.sh test/auto_update/test_install_sh.py -v --install-version 13.3.0 --distro "debian:12"
#   ./test/run_tests.sh -i

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

# ---------- venv setup ----------

setup_venv() {
    if [ ! -d "${VENV_DIR}" ]; then
        echo "Creating virtual environment in ${VENV_DIR}..."
        python3 -m venv "${VENV_DIR}"
    fi

    # shellcheck disable=SC1091
    source "${VENV_DIR}/bin/activate"

    # Install pytest if missing
    if ! python -c "import pytest" 2>/dev/null; then
        echo "Installing pytest..."
        pip install --quiet pytest
    fi
}

# ---------- main ----------

setup_venv

# Check for interactive flag
if [ "${1:-}" = "-i" ] || [ "${1:-}" = "--interactive" ]; then
    shift
    exec python "${SCRIPT_DIR}/interactive_runner.py" "$@"
fi

# Forward all arguments to pytest
exec pytest "$@"
