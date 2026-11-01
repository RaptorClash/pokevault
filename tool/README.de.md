# 🛠️ PokéVault Entwickler- & Wartungswerkzeuge

> **Sprachen:** 🇬🇧 [English](README.md) | 🇩🇪 [Deutsch](README.de.md)

Dieses Verzeichnis enthält Hilfsskripte und Automatisierungen für Entwicklung, Testabdeckung, Datenpipeline und Release-Management.

---

## 📌 Übersicht der Werkzeuge

| Skript / Tool | Sprache | Beschreibung |
| :--- | :--- | :--- |
| [`bump_version.py`](bump_version.py) | Python 3 | Automatisiertes Versions- & Build-Management für `pubspec.yaml` und Git-Releases. |
| [`test_bump_version.py`](test_bump_version.py) | Python 3 | Unit-Test-Suite für `bump_version.py` (SemVer-Validierung, Regex, CLI-Flags). |
| [`run_coverage.ps1`](run_coverage.ps1) | PowerShell | Führt Tests mit Code-Coverage aus und generiert einen LCOV-Bericht. |
| [`data_pipeline/`](data_pipeline/README.de.md) | Python 3 | Scraper, JSON-Importe und SQLite-Kompilierung für `pokedex.sqlite`. |

---

## 🚀 Release Bump Tool (`bump_version.py`)

Das Skript `bump_version.py` liest und aktualisiert die Version in `pubspec.yaml` nach [Semantic Versioning (SemVer)](https://semver.org/) und inkrementiert automatisch die interne Flutter-Build-Nummer (`+<build>`).

### 1. Vorschau ohne Dateiänderungen (`--dry-run`)
Prüft die aktuelle Version und zeigt an, was geändert werden würde:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Ausgabebeispiel:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Version anheben (Build-Nummer automatisch +1)
```bash
python tool/bump_version.py 1.6.0
```
*Aktualisiert `version: 1.5.0+6` $\rightarrow$ `version: 1.6.0+7` in `pubspec.yaml`.*

### 3. Spezifische Build-Nummer vergeben (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Setzt die Version explizit auf `1.6.0+10`.*

### 4. Automatisch Git-Commit und Git-Tag erstellen (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Tests für das Bump-Tool ausführen
Die Logik des Skripts ist durch eine eigenständige Unit-Test-Suite abgesichert:
```bash
python tool/test_bump_version.py
```

---

## 📊 Code-Coverage (`run_coverage.ps1`)

Unter Windows/PowerShell kann die Testabdeckung wie folgt gemessen werden:
```powershell
.\tool\run_coverage.ps1
```
Erzeugt die Datei `coverage/lcov.info` zur weiteren Auswertung.
