# 🛠️ PokéVault Developer & Maintenance Tools

> **Languages:** 🇬🇧 [English](README.md) | 🇩🇪 [Deutsch](README.de.md)

This directory contains utility scripts and automation tools for development, test coverage measurement, offline data pipelines, and release management.

---

## 📌 Tool Overview

| Script / Tool | Language | Description |
| :--- | :--- | :--- |
| [`bump_version.py`](bump_version.py) | Python 3 | Automated version and build number management for `pubspec.yaml` and Git releases. |
| [`test_bump_version.py`](test_bump_version.py) | Python 3 | Unit test suite for `bump_version.py` (SemVer validation, regex matching, CLI flags). |
| [`run_coverage.ps1`](run_coverage.ps1) | PowerShell | Runs tests with code coverage enabled and generates an LCOV report. |
| [`data_pipeline/`](data_pipeline/README.md) | Python 3 | Scrapers, JSON imports, and SQLite compilation pipeline for `pokedex.sqlite`. |

---

## 🚀 Release Bump Tool (`bump_version.py`)

The `bump_version.py` script reads and updates the application version in `pubspec.yaml` adhering to [Semantic Versioning (SemVer)](https://semver.org/), while automatically incrementing Flutter's internal build number (`+<build>`).

### 1. Dry Run / Preview (`--dry-run`)
Inspects the current version and displays the planned changes without modifying any files:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Sample output:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Bump Version (Auto-increment Build Number)
```bash
python tool/bump_version.py 1.6.0
```
*Updates `version: 1.5.0+6` $\rightarrow$ `version: 1.6.0+7` in `pubspec.yaml`.*

### 3. Specify Custom Build Number (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Explicitly sets version to `1.6.0+10`.*

### 4. Automatically Create Git Commit & Tag (`--commit` & `--tag`)
```bash
# Updates pubspec.yaml and creates commit automatically:
python tool/bump_version.py 1.6.0 --commit

# Or create commit and annotated Git tag together:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Run Unit Tests for the Bump Tool
The tool's parsing and validation logic is covered by standalone Python unit tests:
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
