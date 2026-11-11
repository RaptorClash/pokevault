# 🛠️ PokéVault Developer & Maintenance Tools

> **Languages / Sprachen:** [🇩🇪 Deutsch](locales/README.de.md) | **[🇬🇧 English](README.md)** | [🇫🇷 Français](locales/README.fr.md) | [🇪🇸 Español](locales/README.es.md) | [🇮🇹 Italiano](locales/README.it.md) | [🇯🇵 日本語](locales/README.ja.md) | [🇰🇷 한국어](locales/README.ko.md) | [🇨🇳 简体中文](locales/README.zh-hans.md) | [🇹🇼 繁體中文](locales/README.zh-hant.md) | [🇵🇹 Português](locales/README.pt.md) | [🇳🇱 Nederlands](locales/README.nl.md) | [🇵🇱 Polski](locales/README.pl.md) | [🇷🇺 Русский](locales/README.ru.md)

This directory contains utility scripts and automation tools for development, test coverage measurement, offline data pipelines, localization, release notes generation, and release management.

---

## 📌 Tool Overview

| Script / Tool | Language | Description |
| :--- | :--- | :--- |
| [`bump_version.py`](bump_version.py) | Python 3 | Automated version and build number management for `pubspec.yaml` and Git releases. |
| [`test_bump_version.py`](test_bump_version.py) | Python 3 | Unit test suite for `bump_version.py` (SemVer validation, regex matching, CLI flags). |
| [`translate_all.py`](translate_all.py) | Python 3 | Automated multi-engine translation pipeline for UI strings, Slang classes, and documentation in `locales/`. |
| [`translate_release_notes.py`](translate_release_notes.py) | Python 3 | Generates GitHub release notes in all 13 languages formatted into clean collapsible `<details>` dropdowns. |
| [`run_coverage.ps1`](run_coverage.ps1) | PowerShell | Runs tests with code coverage enabled and generates an LCOV report. |
| [`data_pipeline/`](data_pipeline/README.md) | Python 3 | Scrapers, JSON imports, and SQLite compilation pipeline for `pokedex.sqlite`. |

---

## 🌐 Automated Translation Pipeline (`translate_all.py`)

The `translate_all.py` script synchronizes and translates all application strings (`lib/i18n/strings_*.i18n.json`), generates the Dart language registry (`lib/i18n/language_registry.g.dart`), compiles Slang classes, and translates markdown documentation into structured `locales/` subdirectories.

### Key Features:
* **Free Multi-Engine Cascade**: Automatically falls back across Bing $\rightarrow$ Google $\rightarrow$ MyMemory without requiring paid API keys.
* **Optional DeepL Support**: When the `DEEPL_API_KEY` environment variable is configured, DeepL is used as the primary engine.
* **Syntax & Placeholder Protection**: Safely masks Slang parameters (`{name}`, `{count}`), ICU plural blocks (`{count, plural, ...}`), and newlines (`\n`) so translation APIs don't corrupt runtime interpolation.
* **MD5 Cache with Anti-Poisoning**: Persists translations in `tool/.translation_cache.json`. Failed/unchanged source texts are never cached as valid target translations.
* **Request Batching**: Groups strings into chunks (default: 30) separated by delimiters to minimize HTTP requests and avoid rate limits (HTTP 429).
* **Flexible Source Language & Auto-Detection (`--source-lang`)**: Supports translating from English or German, and automatically detects (`auto`) whether English or German was more recently modified.
* **Markdown Link & Navigation Rewriting**: Automatically adjusts relative links between `locales/` subdirectories and parent folders, and builds top language navigation switchers.

### Common CLI Commands:
```bash
# Run full pipeline (UI strings + documentation + Slang compilation)
python tool/translate_all.py

# Dry run preview without making API calls or modifying files
python tool/translate_all.py --dry-run

# Only translate Flutter UI strings
python tool/translate_all.py --app-only

# Only translate documentation (with automatic source language detection)
python tool/translate_all.py --docs-only

# Translate documentation explicitly using English as source
python tool/translate_all.py --docs-only --source-lang en

# Translate only a specific language (e.g. French)
python tool/translate_all.py --lang fr

# Run with 4 concurrent worker threads
python tool/translate_all.py --workers 4
```

### Pipeline Unit Tests:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 📝 Multi-Language Release Notes Generator (`translate_release_notes.py`)

The `translate_release_notes.py` script translates release note drafts into all 13 supported languages and structures them into compact, collapsible GitHub `<details><summary>` dropdowns:
- Title at the top (`# PokéVault v...`)
- Clean list of all 13 languages visible at once with flag icons
- 100% compatible with PokéVault's In-App Updater (`UpdateHelper.filterReleaseNotes`)

### Usage:
```bash
# 1. Write draft notes in tool/RELEASE_NOTES_DRAFT.md
# 2. Run the generator:
python tool/translate_release_notes.py

# Or specify custom input and output paths:
python tool/translate_release_notes.py my_draft.md -o RELEASE_NOTES.md

# Preview without writing output file (Dry Run):
python tool/translate_release_notes.py --dry-run
```

### Tests:
```bash
python test/tool/test_translate_release_notes.py
```

---

## 🚀 Release Bump Tool (`bump_version.py`)

The `bump_version.py` script reads and updates the application version in `pubspec.yaml` adhering to [Semantic Versioning (SemVer)](https://semver.org/), while automatically incrementing Flutter's internal build number (`+<build>`).

### 1. Dry Run / Preview (`--dry-run`)
Inspects the current version and displays the planned changes without modifying any files:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```

### 2. Bump Version (Auto-increment Build Number)
```bash
python tool/bump_version.py 1.6.0
```

### 3. Specify Custom Build Number (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```

### 4. Automatically Create Git Commit & Tag (`--commit` & `--tag`)
```bash
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Run Unit Tests for the Bump Tool
```bash
python tool/test_bump_version.py
```

---

## 📊 Code Coverage (`run_coverage.ps1`)

On Windows/PowerShell, test coverage can be measured with:
```powershell
.\tool\run_coverage.ps1
```
This generates `coverage/lcov.info` for further analysis.
