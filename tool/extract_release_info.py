#!/usr/bin/env python3
"""
Extracts release metadata (release title, version tag, release notes body)
from RELEASE_NOTES.md and pubspec.yaml for automated GitHub Releases.
"""

import argparse
import os
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

def extract_release_title(content: str, fallback_tag: str = "") -> str:
    """Extracts the release subtitle within quotes in the first heading/line of release notes."""
    if not content:
        return fallback_tag

    lines = [line.strip() for line in content.splitlines() if line.strip()]
    if not lines:
        return fallback_tag

    first_line = lines[0]

    # Look for quotes: "...", “...”, or „...“
    match = re.search(r'["“„](.+?)["”"]', first_line)
    if match:
        title = match.group(1).strip()
        if title:
            return title

    # Fallback to cleaning the first heading line
    cleaned = re.sub(r'^[#\s*_-]+', '', first_line).strip()
    return cleaned if cleaned else fallback_tag

def get_pubspec_version(pubspec_path: str = None) -> str:
    """Extracts version string (without build number) from pubspec.yaml."""
    path = Path(pubspec_path) if pubspec_path else (REPO_ROOT / "pubspec.yaml")
    if not path.exists():
        return "1.0.0"

    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("version:"):
                raw_ver = line.split(":", 1)[1].strip()
                # Remove build number (e.g. 1.7.0+9 -> 1.7.0)
                return raw_ver.split("+")[0].strip()
    return "1.0.0"

def determine_release_metadata(
    ref_name: str,
    input_tag: str = "",
    notes_content: str = "",
    pubspec_version: str = "",
    is_prerelease_input: str = "",
) -> dict:
    """Calculates all metadata keys needed for creating a GitHub release."""
    # 1. Determine Tag Name
    tag_name = input_tag.strip() if input_tag else ""
    if not tag_name:
        # If running on a git tag push (e.g. v1.7.0)
        if ref_name and ref_name.startswith("v") and ref_name != "main":
            tag_name = ref_name
        else:
            # Fallback to pubspec version with 'v' prefix
            ver = pubspec_version if pubspec_version else get_pubspec_version()
            tag_name = f"v{ver}" if not ver.startswith("v") else ver

    # 2. Determine Pre-release flag
    tag_lower = tag_name.lower()
    is_pre = (
        "-beta" in tag_lower
        or "-rc" in tag_lower
        or "-alpha" in tag_lower
        or is_prerelease_input.lower() == "true"
    )

    # 3. Determine Title
    release_title = extract_release_title(notes_content, fallback_tag=tag_name)

    return {
        "tag_name": tag_name,
        "release_title": release_title,
        "is_prerelease": is_pre,
    }

def main():
    parser = argparse.ArgumentParser(description="Extract release information for GitHub Actions")
    parser.add_argument("--notes", default="RELEASE_NOTES.md", help="Path to RELEASE_NOTES.md")
    parser.add_argument("--ref", default=os.environ.get("GITHUB_REF_NAME", ""), help="Git ref name (e.g. main or v1.7.0)")
    parser.add_argument("--tag-input", default="", help="Explicit version tag input from workflow")
    parser.add_argument("--prerelease-input", default="", help="Explicit prerelease boolean input")
    parser.add_argument("--github-output", default=os.environ.get("GITHUB_OUTPUT", ""), help="Path to $GITHUB_OUTPUT file")
    args = parser.parse_args()

    notes_path = REPO_ROOT / args.notes
    notes_content = ""
    if notes_path.exists():
        with open(notes_path, "r", encoding="utf-8") as f:
            notes_content = f.read()

    meta = determine_release_metadata(
        ref_name=args.ref,
        input_tag=args.tag_input,
        notes_content=notes_content,
        is_prerelease_input=args.prerelease_input,
    )

    print(f"Tag Name:      {meta['tag_name']}")
    print(f"Release Title: {meta['release_title']}")
    print(f"Is PreRelease: {meta['is_prerelease']}")
    print(f"Body Path:     {args.notes}")

    if args.github_output:
        with open(args.github_output, "a", encoding="utf-8") as f:
            f.write(f"tag_name={meta['tag_name']}\n")
            f.write(f"release_title={meta['release_title']}\n")
            f.write(f"is_prerelease={'true' if meta['is_prerelease'] else 'false'}\n")
            f.write(f"body_path={args.notes}\n")

if __name__ == "__main__":
    main()
