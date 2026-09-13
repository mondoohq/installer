# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# /// script
# requires-python = ">=3.9"
# dependencies = ["requests"]
# ///

import requests
from typing import List, Dict, Set
import sys
import argparse
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime

# Define expected files per endpoint
EXPECTED_FILES = {
    "mondoo": {
        "darwin": ["darwin_universal.pkg"],
        "linux": [
            "linux_386.deb", "linux_386.rpm",
            "linux_amd64.deb", "linux_amd64.rpm",
            "linux_arm64.deb", "linux_arm64.rpm",
            "linux_armv6.deb", "linux_armv6.rpm",
            "linux_armv7.deb", "linux_armv7.rpm",
            "linux_ppc64le.deb", "linux_ppc64le.rpm"
        ],
        "windows": ["windows_amd64.msi", "windows_arm64.msi"]
    },
    "mql": {
        "darwin": ["darwin_amd64.tar.gz", "darwin_arm64.tar.gz"],
        "linux": [
            "linux_386.deb", "linux_386.rpm", "linux_386.tar.gz",
            "linux_amd64.deb", "linux_amd64.rpm", "linux_amd64.tar.gz",
            "linux_arm64.deb", "linux_arm64.rpm", "linux_arm64.tar.gz",
            "linux_armv6.deb", "linux_armv6.rpm", "linux_armv6.tar.gz",
            "linux_armv7.deb", "linux_armv7.rpm", "linux_armv7.tar.gz",
            "linux_ppc64le.deb", "linux_ppc64le.rpm", "linux_ppc64le.tar.gz"
        ],
        "windows": ["windows_amd64.zip", "windows_arm64.zip"]
    },
    "cnspec": {
        "darwin": ["darwin_amd64.tar.gz", "darwin_arm64.tar.gz"],
        "linux": [
            "linux_386.deb", "linux_386.rpm", "linux_386.tar.gz",
            "linux_amd64.deb", "linux_amd64.rpm", "linux_amd64.tar.gz",
            "linux_arm64.deb", "linux_arm64.rpm", "linux_arm64.tar.gz",
            "linux_armv6.deb", "linux_armv6.rpm", "linux_armv6.tar.gz",
            "linux_armv7.deb", "linux_armv7.rpm", "linux_armv7.tar.gz",
            "linux_ppc64le.deb", "linux_ppc64le.rpm", "linux_ppc64le.tar.gz"
        ],
        "windows": ["windows_amd64.zip", "windows_arm64.zip"]
    }
}

def human_size(size_in_bytes: int) -> str:
    """Convert bytes to human readable string"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_in_bytes < 500.0:
            return f"{size_in_bytes:3.1f}{unit}"
        size_in_bytes /= 1024.0
    return f"{size_in_bytes:.1f}GB"

def validate_release_files(url: str, expected_files: Dict[str, List[str]], min_size: int = 500) -> List[str]:
    """
    Validates that all expected file types are present in a release.
    Args:
        url: The URL of the release JSON endpoint
        expected_files: Dictionary of platform-specific expected file suffixes
        min_size: Minimum required file size

    Returns:
        List of error messages, empty if validation successful
    """
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        errors = []
        found_files = {}  # Store filename and size
        version = data.get('version', '')

        print(f"\nValidating version: {version}")
        print(f"{'File':<30} {'Status':<10} {'Size':<10}")
        print("-" * 50)

        # First, collect all files from the release
        for file in data.get('files', []):
            filename = file.get('filename', '')
            size = file.get('size', 0)

            if 'checksums' in filename.lower():
                continue

            # Extract the file suffix
            for platform, suffixes in expected_files.items():
                for suffix in suffixes:
                    if filename.endswith(f"{version}_{suffix}"):
                        found_files[f"{platform}_{suffix}"] = size

        # Check each expected file
        for platform, suffixes in expected_files.items():
            for suffix in suffixes:
                expected = f"{platform}_{suffix}"
                if expected in found_files:
                    size = found_files[expected]
                    status = "FOUND" if size >= min_size else "SMALL"
                    if size < min_size:
                        errors.append(f"File size too small ({size} bytes): {suffix}")
                    print(f"{suffix:<30} {status:<10} {human_size(size):<10}")
                else:
                    errors.append(f"Missing expected file: {suffix}")
                    print(f"{suffix:<30} {'MISSING':<10} {'N/A':<10}")

        if errors:
            print("\nErrors detected:")
            for error in errors:
                print(f"- {error}")
        else:
            print("\nAll files validated successfully")

        return errors


    except requests.exceptions.RequestException as e:
        return [f"Failed to fetch release data: {str(e)}"]
    except ValueError as e:
        return [f"Failed to parse JSON data: {str(e)}"]

# Pre-releases are copied to the bucket and packaged for macOS and Windows, but
# the Linux package jobs (deb/rpm, chocolatey, arch) run only for stable
# releases. The mondoo preview artifact set is therefore smaller than its stable
# one by design, and is listed separately rather than reported as missing files.
CHANNEL_FILE_OVERRIDES = {
    ("mondoo", "preview"): {
        "darwin": ["darwin_universal.pkg"],
        "windows": ["windows_amd64.msi", "windows_arm64.msi"],
    },
}


# The pointer document for each channel. A channel's membership is derived from
# the version's semver pre-release segment, so these two documents are written
# by the same indexing pass and are expected to stay consistent with each other.
CHANNEL_DOCUMENTS = {"stable": "latest.json", "preview": "preview.json"}

# mql and cnspec are released in lockstep on one version, so within a channel
# they are expected to agree. During a release there is a legitimate window
# where mql has published and cnspec has not, so a difference is only treated
# as a fault once the stale document has stopped being recent.
LOCKSTEP_PRODUCTS = ("mql", "cnspec")
RELEASE_WINDOW_MINUTES = 90


def channel_document(product: str, channel: str):
    """Fetch a channel pointer, returning (version, age_in_minutes)."""
    url = f"https://releases.mondoo.com/{product}/{CHANNEL_DOCUMENTS[channel]}"
    response = requests.get(url)
    response.raise_for_status()
    version = response.json().get("version", "")

    age_minutes = None
    last_modified = response.headers.get("last-modified")
    if last_modified:
        written = parsedate_to_datetime(last_modified)
        age_minutes = (datetime.now(timezone.utc) - written).total_seconds() / 60
    return version, age_minutes


def validate_channel_consistency() -> List[str]:
    """
    Check that mql and cnspec agree within each channel.

    Every indexing pass rewrites all of the pointer documents, whether or not
    their contents changed, so each document's last-modified time records the
    last pass that reached it. Two documents that disagree on version and were
    written by different passes mean a pass did not reach both.

    Validating each product on its own cannot see this: both documents are
    individually well-formed and both point at artifacts that exist.
    """
    errors = []

    for channel in CHANNEL_DOCUMENTS:
        print(f"\n{channel} channel")
        print(f"  {'product':<10} {'version':<20} {'written':<12}")
        print("  " + "-" * 44)

        versions = {}
        ages = {}
        for product in LOCKSTEP_PRODUCTS:
            try:
                version, age = channel_document(product, channel)
            except requests.exceptions.RequestException as e:
                errors.append(f"{channel}: cannot read {product} pointer: {e}")
                print(f"  {product:<10} {'UNREACHABLE':<20}")
                continue
            versions[product] = version
            ages[product] = age
            written = f"{age:.0f}m ago" if age is not None else "unknown"
            print(f"  {product:<10} {version:<20} {written:<12}")

        if len(versions) < len(LOCKSTEP_PRODUCTS):
            continue

        distinct = set(versions.values())
        if len(distinct) == 1:
            continue

        # They differ. Recent enough to be a release in flight?
        oldest = max((a for a in ages.values() if a is not None), default=None)
        if oldest is not None and oldest < RELEASE_WINDOW_MINUTES:
            print(
                f"  versions differ, but both pointers were written within "
                f"{oldest:.0f}m; inside the {RELEASE_WINDOW_MINUTES}m release window"
            )
            continue

        detail = ", ".join(f"{p}={v}" for p, v in sorted(versions.items()))
        errors.append(
            f"{channel}: mql and cnspec disagree ({detail}); the stale pointer "
            f"was last written {oldest:.0f}m ago, so an indexing pass did not reach it"
            if oldest is not None
            else f"{channel}: mql and cnspec disagree ({detail})"
        )

    if errors:
        print("\nErrors detected:")
        for error in errors:
            print(f"- {error}")
    else:
        print("\nChannels are consistent")

    return errors


def main():
    parser = argparse.ArgumentParser(description='Validate release files for Mondoo products')
    parser.add_argument(
        'product',
        choices=['mondoo', 'mql', 'cnspec', 'channels'],
        help='Product to validate, or "channels" to compare the channel pointers',
    )
    parser.add_argument(
        '--channel',
        choices=sorted(CHANNEL_DOCUMENTS),
        default='stable',
        help='Channel to validate files for (default: stable)',
    )
    args = parser.parse_args()

    if args.product == 'channels':
        errors = validate_channel_consistency()
        if errors:
            sys.exit(1)
        return

    document = CHANNEL_DOCUMENTS[args.channel]
    url = f"https://releases.mondoo.com/{args.product}/{document}"
    expected = CHANNEL_FILE_OVERRIDES.get(
        (args.product, args.channel), EXPECTED_FILES[args.product]
    )
    print(f"\nValidating {args.product} {args.channel} release at {url}")
    errors = validate_release_files(url, expected)

    if errors:
        sys.exit(1)

if __name__ == "__main__":
    main()
