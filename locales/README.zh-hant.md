# 🔴 神奇寶貝保險庫

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | **[🇹🇼 繁體中文](README.zh-hant.md)** | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** 是一款為寶可夢訓練家、收藏家和閃光獵人設計的全面且可完全自訂的助手，使用 Flutter 開發。無論你是在規劃地區圖鑑、國家圖鑑、型態圖鑑還是閃光圖鑑——PokéVault 都能幫助你輕鬆追蹤進度，並提供你進行閃光捕捉所需的工具。

__徽章區塊_0____換行變量_0____徽章區塊_1____換行變量_1____徽章區塊_2____換行變量_2____徽章區塊_3____換行變量_3____徽章區塊_4__

## ✨ 主要功能

* **Multi-Dex Verwaltung:** Erstelle beliebig viele Tracker für verschiedene Spiele, Generationen oder eigene Challenges.
* **Detailliertes Form-Tracking:** Volle Unterstützung für Regionalformen, Mega-Entwicklungen, Gigadynamax und Spezialformen (Pokusan, Vivillon, Icognito etc.).
* **PC-Box & Listen-Ansicht:** Betrachte deine Pokémon im klassischen 30-Slot "PC-Box"-Raster oder in einer durchsuchbaren Liste mit nahtlosem Drag & Drop.
* **Shiny Tracking & Hunt Counter:** Tracke normale und schillernde (Shiny) Pokémon separat. Integrierter Shiny-Hunt-Zähler mit Echtzeit-Wahrscheinlichkeitsberechnung, Methodenauswahl, Phasen-Historie und Session-Timer mit AFK-Pausenerkennung.
* **🎖️ Dex Completion Cards:** Gestalte, personalisiere und exportiere hochauflösende Erfolgs-Zertifikate, Statistikkarten und Pokémon-Mosaike zum Teilen deines Fortschritts.
* **Passende Pokébälle (Matching Balls):** Erhalte aus der Community kuratierte Empfehlungen für die besten Pokébälle (für die normale *und* die Shiny-Variante)!
* **📊 Fortschrittlicher Fangraten-Rechner:** Präzise Berechnung der Fangwahrscheinlichkeit über alle Generationen hinweg, inkl. spezieller Mechaniken aus *Pokémon Legenden: Arceus* und *Pokémon Legenden: Z-A*.
* **🧬 Shiny-Zucht & Routen-Rechner:** Berechnet mehrstufige Zuchtketten (inkl. Ditto und Baby-Pokémon) und zeigt exakte Wahrscheinlichkeiten für die Ziel-Nachkommen an.
* **📖 Ausführliche Shiny-Hunting-Guides:** Schritt-für-Schritt-Anleitungen für generationsspezifische Methoden (z. B. PokéRadar, DexNav, Sandwich-Rezepte).
* **🎮 In-App Bedienung & Shortcuts Übersicht:** Eigener Screen in den Einstellungen mit plattform-adaptiven Shortcuts, Mausbefehlen und Touch-Gesten.
* **☁️ Cloud Sync & Offline-First:** 100% Offline-fähig mit robuster lokaler SQLite-Datenbank. Optionale Synchronisierung über dein privates Google Drive mit Patch-Merge-Resilienz.
* **Volle Personalisierung:** Unterstützt Dark/Light Mode sowie individuell anpassbare Akzent- und Hintergrundfarben.
* **Mehrsprachig:** Vollständig in 13 Sprachen verfügbar (UI via Slang). Zudem unabhängige Auswahl der Pokémon-Franchise-Sprache (z. B. deutsches UI mit englischen oder japanischen Pokémon-Namen) basierend auf 10 offiziellen Franchise-Sprachen in `pokedex.sqlite`.

## 📸 截圖

| 主頁面 | 電腦盒子視圖 |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **寶可夢詳情與對應球** | **圖鑑創建與篩選** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 入門步驟（本地執行）

### 前提條件
* [Flutter SDK](https://docs.flutter.dev/get-started/install)（建議使用最新穩定版本）
* Dart SDK
* 一個像 VS Code 或 Android Studio 的 IDE

### 安裝
1. 克隆倉庫：
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. 切換到目錄：
   ```bash
   cd pokevault
   ```

3. 下載依賴項：
   ```bash
   flutter pub get
   ```

4. 下載外部資料並初始化子模組：
   下載資料庫所需的最新資料倉庫和維基：
   ```bash
   python3 update_data.py
   ```

5. 生成與優化 SQLite 資料庫：
   *PokéVault 需要一個預編譯的 SQLite 資料庫來存放寶可夢的基礎資料。* 
   執行一體化流程腳本，以單一命令生成並優化 `assets/db/pokedex.sqlite`：
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(或者使用 `--skip-download` 執行，如果你已經擁有外部的網路轉儲，只想重新建立資料庫。)*

6. 啟動應用程式:
   ```bash
   flutter run
   ```

## 🛠️ 建立版本

要建立一個釋出版本，請使用以下其中一個命令：

**Android (APK)：**
```bash
flutter build apk --release
```

**Windows:**
```bash
flutter build windows --release
```

**Linux:**
```bash
flutter build linux --release
```

**Linux AppImage:**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**網頁：**
```bash
flutter build web --release
```

## 📚 Architektur & Dokumentation
* [Architektur-Leitfaden (`ARCHITECTURE.md`)](ARCHITECTURE.zh-hant.md): Detaillierte Übersicht über Systemarchitektur, Provider-State-Management, DAO-Persistenzmodell, Google Drive Sync Coordinator, Isolate-Translation-Bridge und Test-Quality-Gates.
* [Git-Branching & Release-Pipeline (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.zh-hant.md): Offizielles Git-Branching-Modell, Branch-Protection-Regeln, Multi-Plattform-Builds (Android APK, Windows Zip, Linux AppImage/tar.gz) und automatisierte Beta-Pre-Releases.
* [v1.7.0 Roadmap: The Language Expansion (`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md): Vollständige technische Spezifikation für getrennte Sprachen, lokalen REST-Server, Multi-Emulator-Tracking, Desktop-OCR und mobilen Kamera-Scanner.
* [Datenbank-Generierungs-Pipeline (`tool/data_pipeline/locales/README.de.md`)](../tool/data_pipeline/locales/README.zh-hant.md): Dokumentation der Offline-PokeAPI-Datenaufbereitung, Scraper, Matching-Balls-Import, Indizes und Datenbank-Kompilierung.
* [Entwickler- & Release-Werkzeuge (`tool/locales/README.de.md`)](../tool/locales/README.zh-hant.md): Automatisierte Release-Versionsverwaltung (`bump_version.py`), Test-Suites, Code-Coverage und Übersetzungspipeline (`translate_all.py`).

## 🤝 補充資料（社群貢獻）
你是否缺少地點資訊或匹配的球不正確？你可以在目錄 `tool/data_pipeline/` 中的 JSON 檔案補充這些資料（如果存在的話），或者直接透過 Issues/Pull Requests 貢獻。

如果你想貢獻程式碼、功能或錯誤修復，請使用 `.github/ISSUE_TEMPLATE` 資料夾中的相應問題模板，並在自己的功能分支上開啟一個 Pull Request。

## 🙏 感謝與來源
如果沒有來自社群的這些優秀資源，這個應用程式將無法實現：
*   [PokeAPI](https://pokeapi.co/)：基礎資料與官方插畫。
*   [Living Dex 靈感](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v)：作為追蹤器基礎的社群 Google 表單。
*   [匹配寶貝球指南](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959)：社群策劃的 Excel 表格，用於完美寶貝球。
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate)：捕捉率機制。
*   [Google Gemini](https://gemini.google.com)：程式設計與重構的 AI 輔助。
* 以及更多！

## 📄 授權
本專案依 [GNU 通用公共授權 第3版 (GPL-3.0)](../LICENSE) 授權。

**免責聲明:** 寶可夢及所有相關名稱均為任天堂、Creatures Inc. 和 GAME FREAK inc. 的商標和版權。本專案為免費、非商業的粉絲專案，與任天堂無任何關聯，亦不受其支持或贊助。