#!/usr/bin/env python3
"""
PokéVault Release & Version Bumping Utility
------------------------------------------
Automates updating version and build numbers in pubspec.yaml cleanly and safely.
Supports: patch, minor, major, explicit X.Y.Z (auto-increments +build), or explicit X.Y.Z+N.
Includes --dry-run preview and Git release recommendations.
"""

import os
import re
import sys
import argparse
import subprocess

PUBSPEC_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "pubspec.yaml")

def parse_version(version_str: str) -> tuple[str, int]:
    """Parses '1.5.0+6' or '1.5.0' into ('1.5.0', 6)."""
    parts = version_str.strip().split('+')
    v_name = parts[0]
    build = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 1
    return v_name, build

def calculate_next_version(v_name: str, build: int, target: str) -> str:
    """Calculates the next version string based on target (patch, minor, major, or explicit)."""
    semver_parts = [int(p) for p in re.findall(r'\d+', v_name)]
    while len(semver_parts) < 3:
        semver_parts.append(0)
    major, minor, patch = semver_parts[0], semver_parts[1], semver_parts[2]

    target_clean = target.lower().strip()
    next_build = build + 1

    if target_clean == "patch":
        return f"{major}.{minor}.{patch + 1}+{next_build}"
    elif target_clean == "minor":
        return f"{major}.{minor + 1}.0+{next_build}"
    elif target_clean == "major":
        return f"{major + 1}.0.0+{next_build}"
    elif target_clean == "beta":
        beta_match = re.search(r'-beta\.(\d+)', v_name, flags=re.IGNORECASE)
        if beta_match:
            current_beta_num = int(beta_match.group(1))
            base_v = v_name.split('-beta')[0]
            return f"{base_v}-beta.{current_beta_num + 1}+{next_build}"
        else:
            return f"{major}.{minor + 1}.0-beta.1+{next_build}"
    elif "+" in target:
        explicit_parts = target.split("+")
        return f"{explicit_parts[0]}+{int(explicit_parts[1])}"
    else:
        # User specified version like '1.6.0', keep auto-incremented build number
        return f"{target.strip()}+{next_build}"

def update_pubspec_content(content: str, new_version: str) -> str:
    """Replaces the version line in pubspec.yaml content."""
    pattern = r'(^version:\s*)([^\r\n]+)'
    if not re.search(pattern, content, flags=re.MULTILINE):
        raise ValueError("Could not find 'version: ...' line in pubspec.yaml")
    return re.sub(pattern, rf'\g<1>{new_version}', content, flags=re.MULTILINE)

def get_current_pubspec_version(pubspec_path: str = PUBSPEC_PATH) -> str:
    """Reads the current version from pubspec.yaml."""
    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r'^version:\s*([^\r\n]+)', content, flags=re.MULTILINE)
    if not match:
        raise ValueError(f"No version found in {pubspec_path}")
    return match.group(1).strip()

def main():
    parser = argparse.ArgumentParser(description="PokéVault Release Version Bumper")
    parser.add_argument(
        "target",
        nargs="?",
        default=None,
        help="Target bump: 'patch', 'minor', 'major', or specific version (e.g. '1.6.0' or '1.6.0+7')"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate the version change without modifying pubspec.yaml"
    )
    parser.add_argument(
        "--build",
        type=int,
        default=None,
        help="Explicit build number (override default auto-increment)"
    )
    parser.add_argument(
        "--commit",
        action="store_true",
        help="Automatically create a git commit after updating pubspec.yaml"
    )
    parser.add_argument(
        "--tag",
        action="store_true",
        help="Automatically create an annotated git tag after updating pubspec.yaml"
    )

    args = parser.parse_args()

    current_ver = get_current_pubspec_version()
    v_name, build = parse_version(current_ver)

    if not args.target:
        print("=" * 60)
        print("  PokéVault Version Bumper")
        print("=" * 60)
        print(f"Aktuelle Version in pubspec.yaml: {current_ver} (Name: {v_name}, Build: {build})\n")
        print("Mögliche Optionen für den nächsten Release:")
        print(f"  • patch: {calculate_next_version(v_name, build, 'patch')}")
        print(f"  • minor: {calculate_next_version(v_name, build, 'minor')}")
        print(f"  • major: {calculate_next_version(v_name, build, 'major')}")
        print(f"  • beta:  {calculate_next_version(v_name, build, 'beta')}")
        print(f"  • explizit: python tool/bump_version.py 1.7.0-beta.1")
        print("\nBeispiel-Aufruf:")
        print("  python tool/bump_version.py 1.6.0 --dry-run")
        print("  python tool/bump_version.py 1.6.0")
        print("  python tool/bump_version.py 1.6.0 --commit --tag")
        return

    new_ver = calculate_next_version(v_name, build, args.target)
    new_v_name, new_build = parse_version(new_ver)
    if args.build is not None:
        new_build = args.build
        new_ver = f"{new_v_name}+{new_build}"

    print(f"Bumping Version: {current_ver} -> {new_ver}")

    if args.dry_run:
        print("[DRY-RUN] Es wurden keine Dateien geändert.")
        print("Vorgeschlagener Git-Commit:")
        print(f'  git commit -am "chore(release): bump version to {new_ver}"')
        print(f'  git tag -a v{new_v_name} -m "Release v{new_v_name}"')
        return

    # Read and update pubspec.yaml
    with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    new_content = update_pubspec_content(content, new_ver)

    with open(PUBSPEC_PATH, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Erfolgreich aktualisiert: {PUBSPEC_PATH}")

    commit_msg = f"chore(release): bump version to {new_ver}"
    tag_name = f"v{new_v_name}"

    if args.commit:
        try:
            subprocess.run(["git", "add", PUBSPEC_PATH], check=True)
            subprocess.run(["git", "commit", "-m", commit_msg], check=True)
            print(f"Git-Commit erfolgreich erstellt: '{commit_msg}'")
        except subprocess.CalledProcessError as e:
            print(f"Fehler beim Git-Commit: {e}", file=sys.stderr)
            return

    if args.tag:
        try:
            subprocess.run(["git", "tag", "-a", tag_name, "-m", f"Release {tag_name}"], check=True)
            print(f"Git-Tag erfolgreich erstellt: '{tag_name}'")
        except subprocess.CalledProcessError as e:
            print(f"Fehler beim Erstellen des Git-Tags: {e}", file=sys.stderr)
            return

    if not args.commit:
        print("\nEmpfohlene nächste Git-Schritte:")
        print(f'  git commit -am "{commit_msg}"')
        if not args.tag:
            print(f'  git tag -a {tag_name} -m "Release {tag_name}"')

if __name__ == "__main__":
    main()
