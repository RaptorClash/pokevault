# 🛠️ Strumenti di sviluppo e manutenzione PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | **[🇮🇹 Italiano](README.it.md)** | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Questa directory contiene script di supporto e automatizzazioni per sviluppo, copertura dei test, pipeline di traduzione, pipeline dei dati e gestione delle release.

---

## 📌 Panoramica degli strumenti

| Script / Strumento | Linguaggio | Descrizione |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Gestione automatizzata delle versioni e dei build per `pubspec.yaml` e release Git. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Suite di test unitari per `bump_version.py` (validazione SemVer, regex, flag CLI). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Pipeline di traduzione multi-motore completamente automatica per stringhe UI, classi di slang e documentazione. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Esegue i test con copertura del codice e genera un report LCOV. |
| [`data_pipeline/`](../data_pipeline/locales/README.it.md) | Python 3 | Scraper, importazioni JSON e compilazione SQLite per `pokedex.sqlite`. |

---

## 🌐 Pipeline di traduzione automatizzata (`translate_all.py`)

Lo script `translate_all.py` sincronizza e traduce tutte le stringhe dell'app (`lib/i18n/strings_*.i18n.json`), genera la registrazione delle lingue in Dart (`lib/i18n/language_registry.g.dart`), compila Slang e traduce tutte le documentazioni del progetto in sottocartelle `locales/` dedicate.

### Caratteristiche principali:
* **Cascata multi-engine gratuita**: utilizza Bing $\rightarrow$ Google $\rightarrow$ MyMemory senza chiavi API obbligatorie.
* **Supporto DeepL opzionale**: Se la variabile di ambiente `DEEPL_API_KEY` è impostata, DeepL viene utilizzato come priorità.
* **Protezione della sintassi e dei segnaposto**: Protegge i parametri slang (`{name}`, `{count}`), le strutture plurali ICU (`{count, plural, ...}`) e le interruzioni di riga (`\n`) da traduzioni errate.
* **Hash cache MD5 con anti-avvelenamento**: le traduzioni sono archiviate in `tool/.translation_cache.json` memorizzato nella cache in modo persistente; i risultati identici e errati non vengono memorizzati nella cache come validi.
* **Batch di richieste**: combina stringhe in blocchi di 30 per ridurre al minimo le richieste HTTP ed evitare limiti di velocità (HTTP 429).
* **Lingua di origine flessibile e rilevamento automatico (`--source-lang`)**: rileva automaticamente (`auto`) se il file README inglese o tedesco è stato modificato per ultimo oppure consente di forzare manualmente un lingua di origine.
* **Riscrittura collegamenti e navigazione Markdown**: regola automaticamente i collegamenti tra le sottocartelle `locales/` e la directory principale e genera la barra della lingua nell'intestazione dei documenti.

### Comandi CLI importanti:
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

### Test per la pipeline di traduzione:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 Strumento di Aggiornamento Versione (`bump_version.py`)

Lo script `bump_version.py` legge e aggiorna la versione in `pubspec.yaml` seguendo la [Semantic Versioning (SemVer)](https://semver.org/) e incrementa automaticamente il numero di build interno di Flutter (`+<build>`).

### 1. Anteprima senza modifiche ai file (`--dry-run`)
Controlla la versione attuale e mostra cosa verrebbe cambiato:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Esempio di output:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Incrementare la versione (Numero di build +1 automatico)
```bash
python tool/bump_version.py 1.6.0
```
*Aggiornato `version: 1.5.0+6` $
ightarrow$ `version: 1.6.0+7` in `pubspec.yaml`.*

### 3. Assegnare un numero di build specifico (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Imposta esplicitamente la versione su `1.6.0+10`.*

### 4. Creare automaticamente Git-Commit e Git-Tag (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Eseguire i test per lo strumento Bump
La logica dello script è garantita da una suite di unit test indipendente:
```bash
python tool/test_bump_version.py
```

---

## 📊 Copertura del codice (`run_coverage.ps1`)

Su Windows/PowerShell la copertura dei test può essere misurata come segue:
```powershell
.\tool\run_coverage.ps1
```
Genera il file `coverage/lcov.info` per ulteriori valutazioni.
