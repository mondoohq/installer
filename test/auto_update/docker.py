# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Docker container execution for tests."""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .distros import Distro


@dataclass
class DockerRunner:
    """Handles Docker container execution."""

    distro: Distro
    shell_on_failure: bool = False

    def run(self, script: str, mount_workdir: bool = False) -> bool:
        """Run a bash script in a Docker container. Returns True on success."""
        if self.shell_on_failure:
            script = self._inject_shell_trap(script)

        cmd = self._build_docker_command(script, mount_workdir=mount_workdir)
        result = subprocess.run(cmd)
        return result.returncode == 0

    def _build_docker_command(self, script: str, mount_workdir: bool = False) -> list[str]:
        cmd = [
            "docker", "run", "--rm",
            "--pull", "always",
            "--platform", "linux/amd64",
        ]

        if self.shell_on_failure:
            cmd += ["-it"]

        # Mount current directory as /work if requested
        if mount_workdir:
            import os
            cmd += ["-v", f"{os.getcwd()}:/work:ro"]

        # Arch Linux needs seccomp disabled for pacman's alpm sandbox
        if self.distro.pkg_mgr_name == "pacman":
            cmd += ["--security-opt", "seccomp=unconfined"]

        # Add tmpfs mounts for package manager cache
        for path, opts in self.distro.pkg_mgr.docker_tmpfs_mounts:
            cmd += ["--tmpfs", f"{path}:{opts}"]

        cmd += [self.distro.image, "bash", "-c", script]
        return cmd

    @staticmethod
    def _inject_shell_trap(script: str) -> str:
        """Inject a bash ERR trap that drops to an interactive shell on failure."""
        trap = 'trap \'echo "--- dropping to shell ---"; exec bash\' ERR\n'
        return script.replace("set -e\n", f"set -e\n{trap}", 1)
