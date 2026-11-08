# 🛠️ PokéVault ontwikkelaar- & onderhoudsgereedschappen

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | **[🇳🇱 Nederlands](README.nl.md)** | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Deze directory bevat hulpscripts en automatiseringen voor ontwikkeling, testdekking, vertaalpijplijn, datapuntenpijplijn en releasebeheer.

---

## 📌 Overzicht van de gereedschappen

| Skript / Tool | Taal | Beschrijving |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Geautomatiseerd versie- & buildbeheer voor `pubspec.yaml` en Git-releases. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Unit-testsuite voor `bump_version.py` (SemVer-validatie, Regex, CLI-vlaggen). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Volledig automatische multi-engine vertaalpipeline voor UI-strings, slangklassen en documentatie. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Voert tests uit met code-coverage en genereert een LCOV-rapport. |
| [`data_pipeline/`](../data_pipeline/locales/README.nl.md) | Python 3 | Scraper, JSON-imports en SQLite-compilatie voor `pokedex.sqlite`. |

---

## 🌐 Geautomatiseerde vertaalpijplijn (`translate_all.py`)

Het script `translate_all.py` synchroniseert en vertaalt alle app-strings (`lib/i18n/strings_*.i18n.json`), genereert de Dart-taalregistratie (`lib/i18n/language_registry.g.dart`), compileert Slang en vertaalt alle projectdocumentaties naar toegewijde `locales/`-submappen.

### Belangrijkste kenmerken:
* **Gratis multi-engine cascade**: gebruikt Bing $\rightarrow$ Google $\rightarrow$ MyMemory zonder verplichte API-sleutels.
* **Optionele DeepL-ondersteuning**: als de omgevingsvariabele `DEEPL_API_KEY` is ingesteld, wordt DeepL als prioriteit gebruikt.
* **Syntaxis- en tijdelijke bescherming**: beschermt slangparameters (`{name}`, `{count}`), ICU-meervoudsstructuren (`{count, plural, ...}`) en regeleinden (`\n`) van verkeerde vertalingen.
* **MD5-hash-cache met anti-vergiftiging**: vertalingen worden permanent opgeslagen in `tool/.translation_cache.json` in de cache; onjuiste identieke retourzendingen worden niet als geldig in de cache opgeslagen.
* **Verzoek batching**: Combineert tekenreeksen in blokken van 30 om HTTP-verzoeken te minimaliseren en snelheidslimieten te vermijden (HTTP 429).
* **Flexibele brontaal en automatische detectie (`--source-lang`)**: Detecteert automatisch (`auto`) of de Engelse of Duitse README voor het laatst is bewerkt, of staat handmatige forcering van een bron toe taal.
* **Markdown Link & Navigation Rewriting**: Past automatisch de koppelingen aan tussen `locales/` submappen en de hoofdmap en genereert de taalbalk in de kop van de documenten.

### Belangrijke CLI-commando's:
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

### Tests voor de vertaalpipeline:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 Release Bump Tool (`bump_version.py`)

Het script `bump_version.py` leest en werkt de versie bij in `pubspec.yaml` volgens [Semantic Versioning (SemVer)](https://semver.org/) en verhoogt automatisch het interne Flutter-buildnummer (`+<build>`).

### 1. Voorvertoning zonder bestandswijzigingen (`--dry-run`)
Controleert de huidige versie en geeft aan wat er zou worden gewijzigd:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Voorbeeld van uitvoer:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Versie verhogen (Build-nummer automatisch +1)
```bash
python tool/bump_version.py 1.6.0
```
*Bijgewerkt `version: 1.5.0+6` $
ightarrow$ `version: 1.6.0+7` in `pubspec.yaml`.*

### 3. Specifiek buildnummer toekennen (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Stelt de versie expliciet in op `1.6.0+10`.*

### 4. Automatisch Git-Commit en Git-Tag aanmaken (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Tests uitvoeren voor het bump-gereedschap
De logica van het script is beveiligd door een zelfstandige unit-testsuite:
```bash
python tool/test_bump_version.py
```

---

## 📊 Code-dekking (`run_coverage.ps1`)

Onder Windows/PowerShell kan de testdekking als volgt worden gemeten:
```powershell
.\tool\run_coverage.ps1
```
Maakt het bestand `coverage/lcov.info` aan voor verdere evaluatie.
