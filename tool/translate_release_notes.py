#!/usr/bin/env python3
"""PokéVault Automated Multi-Language Release Notes Generator.

Translates release notes into all 13 supported languages configured in lib/i18n/languages.json
and generates an ultra-clean, collapsible markdown format for GitHub Releases:
- Main title at the top
- Every language cleanly folded into its own `<details><summary>` dropdown
- Fully compatible with PokéVault's In-App Updater (`UpdateHelper.filterReleaseNotes`)
"""

import os
import sys
import re
import argparse
from pathlib import Path

# Ensure stdout uses UTF-8 on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

REPO_ROOT = Path(__file__).resolve().parent.parent

# Import translation utilities and cache from translate_all.py
sys.path.insert(0, str(REPO_ROOT / "tool"))
from translate_all import (
    load_languages_config,
    load_cache,
    save_cache,
    translate_single_string,
)

DEFAULT_DRAFT_PATH = REPO_ROOT / "RELEASE_NOTES_DRAFT.md"
DEFAULT_OUTPUT_PATH = REPO_ROOT / "RELEASE_NOTES.md"

def parse_draft_notes(content: str) -> tuple[str, str, str]:
    """Parses a draft markdown note into title, body, and footer (e.g. Full Changelog)."""
    lines = content.strip().splitlines()
    if not lines:
        return "", "", ""

    title = ""
    start_idx = 0
    if lines[0].strip().startswith("# "):
        title = lines[0].strip()
        start_idx = 1

    footer = ""
    end_idx = len(lines)
    for idx in range(len(lines) - 1, start_idx - 1, -1):
        line_clean = lines[idx].strip()
        if line_clean.startswith("**Full Changelog**:") or line_clean.startswith("Full Changelog:"):
            footer = "\n".join(lines[idx:]).strip()
            end_idx = idx
            break

    body = "\n".join(lines[start_idx:end_idx]).strip()
    return title, body, footer

def detect_draft_source_lang(text: str) -> str:
    """Detects whether draft release notes are written in German or English."""
    lower = text.lower()
    german_indicators = ["neue funktionen", "verbesserungen", "fehlerbehebungen", "behoben", "hinzugefügt", "unterstützung"]
    english_indicators = ["new features", "improvements", "bug fixes", "fixed", "added", "support"]

    de_score = sum(1 for word in german_indicators if word in lower)
    en_score = sum(1 for word in english_indicators if word in lower)

    return "de" if de_score > en_score else "en"

def translate_release_body(body: str, target_lang: str, cache, source_lang: str = "en") -> str:
    """Translates the release notes body preserving bullet points, bold text, and paragraphs."""
    if source_lang.lower() == target_lang.lower():
        return body

    paragraphs = body.split("\n\n")
    translated_paras = []

    for para in paragraphs:
        para_clean = para.strip()
        if not para_clean:
            translated_paras.append("")
            continue

        # If it's a list of bullet points, translate lines individually to maintain markdown bullets
        if "\n* " in para_clean or para_clean.startswith("* "):
            bullet_lines = para_clean.split("\n")
            translated_lines = []
            for bl in bullet_lines:
                bl_clean = bl.strip()
                if not bl_clean:
                    continue
                if bl_clean.startswith("* ") or bl_clean.startswith("- "):
                    prefix = bl_clean[:2]
                    content = bl_clean[2:].strip()
                    trans_content = translate_single_string(content, target_lang, cache, source_lang=source_lang)
                    translated_lines.append(f"{prefix}{trans_content}")
                else:
                    trans_line = translate_single_string(bl_clean, target_lang, cache, source_lang=source_lang)
                    translated_lines.append(trans_line)
            translated_paras.append("\n".join(translated_lines))
        else:
            trans_para = translate_single_string(para_clean, target_lang, cache, source_lang=source_lang)
            translated_paras.append(trans_para)

    return "\n\n".join(translated_paras)

def format_collapsible_release_notes(title: str, translations: dict, languages: list, footer: str = "") -> str:
    """Formats all language release notes into clean GitHub <details><summary> collapsible dropdowns."""
    output_parts = []
    if title:
        output_parts.append(title)
        output_parts.append("")

    for lang in languages:
        code = lang["code"]
        flag = lang["flag"]
        native = lang["nameNative"]
        content = translations.get(code, "").strip()

        if not content:
            continue

        block = (
            f"<details>\n"
            f"<summary>{flag} <b>{native}</b></summary>\n\n"
            f"{content}\n\n"
            f"</details>"
        )
        output_parts.append(block)

    if footer:
        output_parts.append("")
        output_parts.append(footer)

    return "\n".join(output_parts).strip() + "\n"

def main():
    parser = argparse.ArgumentParser(description="PokéVault Multi-Language Release Notes Generator")
    parser.add_argument("input_file", nargs="?", default=str(DEFAULT_DRAFT_PATH), help="Path to draft release notes markdown file")
    parser.add_argument("-o", "--output", default=str(DEFAULT_OUTPUT_PATH), help="Path to output markdown file (default: RELEASE_NOTES.md)")
    parser.add_argument("--source-lang", default="auto", help="Source language of the draft ('auto', 'de', 'en', default: 'auto')")
    parser.add_argument("--dry-run", action="store_true", help="Print summary without writing output file")
    args = parser.parse_args()

    input_path = Path(args.input_file)
    if not input_path.exists():
        print(f"Error: Draft file '{input_path}' not found!")
        print("Please create the file or specify a valid path (e.g. python tool/translate_release_notes.py my_draft.md)")
        sys.exit(1)

    with open(input_path, "r", encoding="utf-8") as f:
        draft_content = f.read()

    title, body, footer = parse_draft_notes(draft_content)
    if not body:
        print("Error: Draft notes body is empty!")
        sys.exit(1)

    effective_source = args.source_lang
    if effective_source == "auto":
        effective_source = detect_draft_source_lang(body)

    languages = load_languages_config()
    cache = load_cache()

    print(f"Draft Title: {title or '(No title)'}")
    print(f"Source Language detected: {effective_source}")
    print(f"Translating into {len(languages)} languages...")

    translations = {}
    translations[effective_source] = body

    for lang in languages:
        code = lang["code"]
        if code.lower() == effective_source.lower():
            continue

        print(f"  -> Translating to {code} ({lang['nameNative']})...", flush=True)
        trans_body = translate_release_body(body, code, cache, source_lang=effective_source)
        translations[code] = trans_body

    save_cache(cache)

    formatted_md = format_collapsible_release_notes(title, translations, languages, footer=footer)

    if args.dry_run:
        print("\n--- [DRY-RUN OUTPUT PREVIEW] ---")
        print(formatted_md[:1000] + "\n...(truncated)")
    else:
        out_path = Path(args.output)
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(formatted_md)
        print(f"\n[+] Successfully generated multi-language release notes in: {out_path}")

if __name__ == "__main__":
    main()
