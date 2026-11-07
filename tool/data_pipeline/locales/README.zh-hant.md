# PokéVault 數據庫生成管線 (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | **[🇹🇼 繁體中文](README.zh-hant.md)** | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

此目錄包含用於 PokéVault 的 SQLite 參考資料庫 `assets/db/pokedex.sqlite` 的完整離線資料管線的建立和優化。

---

## 1. 概覽與目標設定

PokéVault 遵循 **離線優先** 原則。所有靜態特許經營資料（寶可夢基礎數值、替代形態、捕捉率、緞帶、招式學習表、出現地點、閃光鎖、多語言種族名稱及相應寶貝球）都會在建置時預先彙總到 SQLite 資料庫中，並與應用程式一起提供。

因此，運行時不需要慢速的 API 查詢，用戶可以在任何地方無需網路連線使用應用程式。

---

## 2. 系統需求與設定

- **Python 3.10 或更高版本**
- **Git**，需支援子模組
- 安裝所需的 Python 套件：
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- 初始化 Git 子模組：
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. 資料來源與目錄結構

該管道將來自多個可信來源的數據整合在一起：

```text
tool/data_pipeline/
├── run_pipeline.py                 # All-in-One Runner: Führt alle Schritte nacheinander aus
├── build_database.py               # Hauptskript zur Datenbank-Kompilierung
├── database_constants.py           # Typen, Generationen-Mappings & ID-Konstanten
├── update_pokemon_languages.py     # Synchronisiert mehrsprachige Pokémon-Namen aus PokeAPI
├── update_evolutions_db.py         # Skript für komplexe Entwicklungsbäume
├── update_cap_locks_and_trades.py  # Skript für Kappen-, Cosplay- & Tausch-Locks
├── optimize_databases.py           # Indexierung, PRAGMA ANALYZE & VACUUM
├── api-data/                       # Git-Submodul: Offizieller PokeAPI JSON-Dump
├── ribbons_guide/                  # Git-Submodul: Ribbons.Guide Referenz
├── Legal_Matching_Pokeballs.xlsx   # Community-Excel mit legalen Ball-Kombinationen
├── custom_encounters.json          # Manuelle Ergänzungen für Fundorte
├── custom_matching_balls.json      # Manuelle Overrides für empfohlene Bälle
└── *.html                          # Offline HTML-Caches (Bulbapedia, PokéWiki, Bisafans)
```

1. **[PokeAPI](https://pokeapi.co/) (`api-data/`)**:
   - Bereitstellung strukturierter JSON-Dateien für Pokémon-Stammdaten, Basiswerte, Typen, Fähigkeiten, Attacken-Learnsets, mehrsprachige Artnamen und Entwicklungen.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
   - Deutsche Namen, Bänder- & Zeichenbeschreibungen (`Liste aller Bänder`, `Zeichen`), Geschlechtsunterschiede und Schillernde Pokémon.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
   - Globale Bänder-Listen, In-Game-Trades und Gift-Pokémon über alle Generationen (als Offline-HTML gesichert).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
   - Detaillierte Listen editionsspezifischer Geschenke und Tausche von Kanto bis Paldea und Z-A.
5. **Community Spreadsheet (`Legal_Matching_Pokeballs.xlsx`)**:
   - Detaillierte Matrix aller fangbaren Pokémon je Edition und passender Pokéball-Ästhetik.

---

## 4. 快速整體執行（全方位運行器）

要使用單一命令按照正確的順序運行包含所有腳本的整個流程，請使用 `run_pipeline.py`：

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

這個執行程式會自動處理：
1. `update_data.py`（更新外部資料和 Git 子模組）
2. `build_database.py`（使用基礎資料生成 `assets/db/pokedex.sqlite`）
3. `update_pokemon_languages.py`（同步所有 10 個系列語言的所有物種）
4. `update_evolutions_db.py`（豐富進化樹資料）
5. `update_cap_locks_and_trades.py`（新增帽子、Cosplay 及交易鎖定）
6. `optimize_databases.py`（建立覆蓋索引、執行 `ANALYZE`、`VACUUM`）

---

## 5. 手動流程（單步驟）

如果要手動執行單個腳本：

### 步驟 1：更新外部原始資料與子模組
```bash
python update_data.py
```
*下載最新的 HTML 快取，拉取最新的 `Legal_Matching_Pokeballs.xlsx`，並將 `api-data` 子模組更新至最新版本。*

### 步驟 2：建立 SQLite 主資料庫
```bash
python tool/data_pipeline/build_database.py
```
*建立 `assets/db/pokedex.sqlite`，讀取所有 1,025+ 寶可夢和 250+ 形態，並聚合超過 500 個閃光鎖定。*

### 步驟 3：同步多語言寶可夢名稱
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*動態讀取 `lib/i18n/languages.json` 中的所有品牌語言，用 `ALTER TABLE` 新增缺少的欄位（`name_fr`、`name_ja` 等），並從離線 PokeAPI JSON 填入名稱。*

### 第4步：豐富開發樹
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*計算開發樹、分支和觸發器。*

### 第5步：導入帽子、Cosplay 與交換寶可夢
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*將帽子皮卡丘、Cosplay 形態及交換寶可夢導入 `assets/db/pokedex.sqlite` 與 `database/pokedex.sqlite`。*

### 步驟 6：建立索引、優化與 VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*建立覆蓋索引，執行 `ANALYZE`、`PRAGMA optimize;` 和 `VACUUM`。*

---

## 6. `pokedex.sqlite` 中的表格概覽

| Tabelle | Beschreibung | Wichtige Indizes |
|---|---|---|
| `pokemon` | Basisdaten aller 1.025+ Pokémon inkl. 10 Franchise-Sprachspalten (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `PRIMARY KEY (id)` |
| `forms` | Alternative Formen, Mega, G-Max, Regional | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Regionale Pokédex-Reihenfolgen | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `special_dexes` | Spezial-Dexe (z. B. Legendary, Ultra Beasts) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` | Attacken-Learnsets aller Versionen | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `pokemon_abilities` | Fähigkeiten & Hidden Abilities | `idx_pokemon_abilities_poke (pokemon_id)` |
| `encounters` | Fundorte und Begegnungstypen | `idx_encounters_poke (pokemon_id, version_group)` |
| `evolutions` | Vollständige Entwicklungsbäume | `PRIMARY KEY (species_id)` |
| `ribbons` | Bänder aller Generationen | `PRIMARY KEY (id)` |
| `marks` | Zeichen aller Editionen | `PRIMARY KEY (id)` |
| `shiny_locks` | Sämtliche Shiny-Locks (Global & Edition) | `PRIMARY KEY (pokemon_id, form_name, game_version)` |
| `legal_balls` | Legale Pokébälle je Pokémon & Edition | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. 驗證與品質保證

在每次執行管線之後，必須確保生成的資料庫是完整且無錯誤的：

```powershell
# 1. Datenbank-spezifische Tests ausführen
flutter test test/database/
flutter test test/db/

# 2. Shiny-Lock Tests ausführen
flutter test test/services/shiny_lock_service_test.dart
flutter test test/screens/pokemon_info/shiny_lock_ui_test.dart

# 3. Fangraten- & Matching-Ball Tests
flutter test test/screens/pokemon_info/catch_rate_calculator_test.dart
```

---

## 8. 路徑與開發規範

此目錄中的所有腳本都使用動態的、相對的路徑解析：
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- 絕不要硬編碼絕對操作系統路徑。
- 不要在 `assets/data/` 中放置臨時 JSON 文件；所有靜態數據應直接放入關聯式 SQLite 數據庫 `assets/db/pokedex.sqlite`。
