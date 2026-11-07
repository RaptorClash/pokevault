# 🛠️ PokéVault Entwickler- & Wartungswerkzeuge

> **Languages / Sprachen:** [🇬🇧 English](../README.md) | **[🇩🇪 Deutsch](README.de.md)** | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Dieses Verzeichnis enthält Hilfsskripte und Automatisierungen für Entwicklung, Testabdeckung, Übersetzungspipeline, Release-Notes-Generierung, Datenpipeline und Release-Management.

---

## 📌 Übersicht der Werkzeuge

| Skript / Tool | Sprache | Beschreibung |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Automatisiertes Versions- & Build-Management für `pubspec.yaml` und Git-Releases. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Unit-Test-Suite für `bump_version.py` (SemVer-Validierung, Regex, CLI-Flags). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Vollautomatische Multi-Engine-Übersetzungspipeline für UI-Strings, Slang-Klassen und Dokumentationen. |
| [`translate_release_notes.py`](../translate_release_notes.py) | Python 3 | Generiert GitHub Release Notes in allen 13 Sprachen formatiert in aufklappbaren `<details>`-Dropdowns. |
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

## 📝 Multi-Language Release Notes Generator (`translate_release_notes.py`)

Das Skript `translate_release_notes.py` übersetzt Release-Notes-Entwürfe automatisch in alle 13 Sprachen und formatiert sie in ein kompaktes, einklappbares GitHub-Markdown-Format:
- Oben steht der Haupttitel (`# PokéVault v...`)
- Darunter erscheint direkt eine übersichtliche Liste aller 13 Sprachen mit Flaggen als aufklappbare `<details><summary>`-Dropdowns
- Voll kompatibel mit dem In-App-Updater von PokéVault (`UpdateHelper.filterReleaseNotes`)

### Verwendung:
```bash
# 1. Entwurf in RELEASE_NOTES_DRAFT.md schreiben
# 2. Skript ausführen:
python tool/translate_release_notes.py

# Alternativ mit spezifischer Entwurfsdatei:
python tool/translate_release_notes.py my_draft.md -o RELEASE_NOTES.md

# Vorschau ohne Datei zu schreiben (Dry-Run):
python tool/translate_release_notes.py --dry-run
```

### Tests:
```bash
python test/tool/test_translate_release_notes.py
```

---

## 🚀 Release Bump Tool (`bump_version.py`)

Das Skript `bump_version.py` liest und aktualisiert die Version in `pubspec.yaml` nach [Semantic Versioning (SemVer)](https://semver.org/) und inkrementiert automatisch die interne Flutter-Build-Nummer (`+<build>`).

### 1. Vorschau ohne Dateiänderungen (`--dry-run`)
Prüft die aktuelle Version und zeigt an, was geändert werden würde:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```

### 2. Version anheben (Build-Nummer automatisch +1)
```bash
python tool/bump_version.py 1.6.0
```

### 3. Spezifische Build-Nummer vergeben (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```

### 4. Automatisch Git-Commit und Git-Tag erstellen (`--commit` & `--tag`)
```bash
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Tests für das Bump-Tool ausführen
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
