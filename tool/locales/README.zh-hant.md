# 🛠️ PokéVault 開發與維護工具

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | **[🇹🇼 繁體中文](README.zh-hant.md)** | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

此目錄包含用於開發、測試覆蓋率、翻譯流程、數據流程和發布管理的輔助腳本和自動化工具。

---

## 📌 工具概覽

| 腳本 / 工具 | 語言 | 說明 |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | 自動化 `pubspec.yaml` 與 Git 發行版本管理 |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | `bump_version.py` 的單元測試套件（SemVer 驗證、正則表達式、命令列標誌） |
| [`translate_all.py`](../translate_all.py) | Python 3 | 用於 UI 字串、俚語類別及文件的全自動多引擎翻譯管線 |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | 執行測試並帶有程式碼覆蓋率，生成 LCOV 報告 |
| [`data_pipeline/`](../data_pipeline/locales/README.zh-hant.md) | Python 3 | 用於 `pokedex.sqlite` 的爬蟲、JSON 匯入與 SQLite 編譯 |

---

## 🌐 自動化翻譯管線 (`translate_all.py`)

腳本 `translate_all.py` 會同步並翻譯所有應用程式字串（`lib/i18n/strings_*.i18n.json`）、生成 Dart 語言登記（`lib/i18n/language_registry.g.dart`）、編譯 Slang，並將所有專案文件翻譯到專用的 `locales/` 子資料夾中。

### Hauptmerkmale:
* **Kostenlose Multi-Engine-Kaskade**: Verwendet Bing $\rightarrow$ Google $\rightarrow$ MyMemory ganz ohne zwingend erforderliche API-Keys.
* **Optionale DeepL-Unterstützung**: Bei gesetzter Umgebungsvariable `DEEPL_API_KEY` wird prioritär DeepL verwendet.
* **Syntax- & Placeholder-Schutz**: Schützt Slang-Parameter (`{name}`, `{count}`), ICU-Pluralstrukturen (`{count, plural, ...}`) und Zeilenumbrüche (`\n`) vor Fehlübersetzungen.
* **MD5-Hash-Cache mit Anti-Poisoning**: Übersetzungen werden in `tool/.translation_cache.json` persistent gecacht; fehlerhafte identische Rückgaben werden nicht als valide gecacht.
* **Request-Batching**: Fasst Strings in 30er-Blöcken zusammen, um HTTP-Requests zu minimieren und Rate-Limits (HTTP 429) zu vermeiden.
* **Flexible Quellsprache & Auto-Detection (`--source-lang`)**: Erkennt automatisch (`auto`), ob die englische oder deutsche README zuletzt bearbeitet wurde, oder erlaubt das manuelle Forcieren einer Quellsprache.
* **Markdown Link- & Navigations-Rewriting**: Passt Links zwischen `locales/`-Unterordnern und dem Hauptverzeichnis automatisch an und generiert die Sprachleiste im Kopf der Dokumente.

### 重要的 CLI 指令：
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

### 翻譯流程測試:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 發行版本更新工具 (`bump_version.py`)

腳本 `bump_version.py` 會讀取並更新 `pubspec.yaml` 中的版本，遵循 [語義化版本控制 (SemVer)](https://semver.org/)，並自動遞增內部 Flutter 編譯號碼 (`+<build>`)。

### 1. 預覽而不更改檔案 (`--dry-run`)
檢查當前版本並顯示將會更改的內容：
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*輸出範例：*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. 提升版本（構建號自動 +1)
```bash
python tool/bump_version.py 1.6.0
```
*已在 `pubspec.yaml` 中將 `version: 1.5.0+6` 更新為 `version: 1.6.0+7`。*

### 3. 指定特定的建置號碼 (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*將版本明確設置為 `1.6.0+10`。*

### 4. 自動建立 Git 提交和 Git 標籤 (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. 執行 Bump 工具的測試
腳本的邏輯已通過獨立的單元測試套件進行保障：
```bash
python tool/test_bump_version.py
```

---

## 📊 程式碼覆蓋率 (`run_coverage.ps1`)

在 Windows/PowerShell 下，測試覆蓋率可以如下測量：
```powershell
.\tool\run_coverage.ps1
```
生成文件 `coverage/lcov.info` 以便進一步分析。
