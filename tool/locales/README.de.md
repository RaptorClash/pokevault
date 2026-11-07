# 🛠️ PokéVault Entwickler- & Wartungswerkzeuge

> **Languages / Sprachen:** **[🇩🇪 Deutsch](README.de.md)** | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Dieses Verzeichnis enthält Hilfsskripte und Automatisierungen für Entwicklung, Testabdeckung, Übersetzungspipeline, Datenpipeline und Release-Management.

---

## 📌 Übersicht der Werkzeuge

| Skript / Tool | Sprache | Beschreibung |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Automatisiertes Versions- & Build-Management für `pubspec.yaml` und Git-Releases. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Unit-Test-Suite für `bump_version.py` (SemVer-Validierung, Regex, CLI-Flags). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Vollautomatische Multi-Engine-Übersetzungspipeline für UI-Strings, Slang-Klassen und Dokumentationen. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Führt Tests mit Code-Coverage aus und generiert einen LCOV-Bericht. |
| [`data_pipeline/`](../data_pipeline/locales/README.de.md) | Python 3 | Scraper, JSON-Importe und SQLite-Kompilierung für `pokedex.sqlite`. |

---

## 🌐 Automatisierte Übersetzungspipeline (`translate_all.py`)

Das Skript `translate_all.py` synchronisiert und übersetzt sämtliche App-Strings (`lib/i18n/strings_*.i18n.json`), generiert die Dart-Sprachregistrierung (`lib/i18n/language_registry.g.dart`), kompiliert Slang und übersetzt alle Projekt-Dokumentationen in dedizierte `locales/`-Unterordner.

### Hauptmerkmale:
* **Kostenlose Multi-Engine-Kaskade**: Verwendet Bing $\rightarrow$ Google $\rightarrow$ MyMemory ganz ohne zwingend erforderliche API-Keys.
* **Optionale DeepL-Unterstützung**: Bei gesetzter Umgebungsvariable `DEEPL_API_KEY` wird prioritär DeepL verwendet.
* **Syntax- & Placeholder-Schutz**: Schützt Slang-Parameter (`{name}`, `{count}`), ICU-Pluralstrukturen (`{count, plural, ...}`) und Zeilenumbrüche (`\n`) vor Fehlübersetzungen.
* **MD5-Hash-Cache mit Anti-Poisoning**: Übersetzungen werden in `tool/.translation_cache.json` persistent gecacht; fehlerhafte identische Rückgaben werden nicht als valide gecacht.
* **Request-Batching**: Fasst Strings in 30er-Blöcken zusammen, um HTTP-Requests zu minimieren und Rate-Limits (HTTP 429) zu vermeiden.
* **Flexible Quellsprache & Auto-Detection (`--source-lang`)**: Erkennt automatisch (`auto`), ob die englische oder deutsche README zuletzt bearbeitet wurde, oder erlaubt das manuelle Forcieren einer Quellsprache.
* **Markdown Link- & Navigations-Rewriting**: Passt Links zwischen `locales/`-Unterordnern und dem Hauptverzeichnis automatisch an und generiert die Sprachleiste im Kopf der Dokumente.

### Wichtige CLI-Befehle:
```bash
# Gesamte Pipeline ausführen (UI-Strings + Dokumentationen + Slang-Kompilierung)
python tool/translate_all.py

# Vorschau ohne Dateiänderungen oder Translation-API-Aufrufe
python tool/translate_all.py --dry-run

# Nur Flutter-UI-Strings übersetzen
python tool/translate_all.py --app-only

# Nur Dokumentation übersetzen (mit automatischer Quellsprachen-Erkennung)
python tool/translate_all.py --docs-only

# Dokumentation explizit aus dem Englischen in alle Sprachen übersetzen
python tool/translate_all.py --docs-only --source-lang en

# Nur eine bestimmte Zielsprache übersetzen (z. B. Französisch)
python tool/translate_all.py --lang fr

# Multithreaded-Übersetzung mit 4 Workern
python tool/translate_all.py --workers 4
```

### Tests für die Übersetzungspipeline:
```bash
python test/tool/test_translation_pipeline.py
```

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
