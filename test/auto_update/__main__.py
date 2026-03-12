# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Entry point for running as a module: python -m auto_update

Usage examples:
    # Run all tests
    pytest test/auto_update --install-version 13.0.0

    # Run specific test types
    pytest test/auto_update -m auto_update --install-version 13.0.0
    pytest test/auto_update -m mondoo_pkg --install-version 13.0.0
    pytest test/auto_update -m upgrade --install-version 13.0.0

    # Run for specific distros
    pytest test/auto_update --install-version 13.0.0 --distro debian:11

    # Run install.sh upgrade tests
    pytest test/auto_update -m install_sh --install-version 13.0.0 --install-sh-upgrade-from 12.0.0

    # Run AUR tests only
    pytest test/auto_update -m aur --install-version 13.0.0

    # Legacy CLI (still supported for backwards compatibility)
    python -m auto_update --install-version 13.0.0 --tests all
"""

import sys


def main() -> None:
    """Main entry point - delegates to pytest or legacy CLI."""
    # If running via pytest (e.g., pytest test/auto_update), this module isn't used
    # If running via python -m auto_update, check for legacy flags
    if "--tests" in sys.argv or any(arg.startswith("--skip-tests") for arg in sys.argv):
        # Legacy CLI mode
        from .cli import main as cli_main
        cli_main()
    else:
        # Modern pytest mode - pass through to pytest
        import pytest
        # Remove the module name from argv, add the test directory
        args = sys.argv[1:] + [__file__.rsplit("/", 1)[0]]
        sys.exit(pytest.main(args))


if __name__ == "__main__":
    main()
