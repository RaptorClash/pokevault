# PokéVault 数据库生成管道 (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | **[🇨🇳 简体中文](README.zh-hans.md)** | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

该目录包含用于为 PokéVault 创建和优化 SQLite 参考数据库 `assets/db/pokedex.sqlite` 的完整离线数据管道。

---

## 1. 概述与目标

PokéVault 按照 **离线优先** 原则工作。所有静态特许经营数据（宝可梦基础值、替代形态、捕获率、绷带、招式学习表、出现地点、闪光锁、多语言种族名称和相应的精灵球）都会在构建时预聚合到 SQLite 数据库中，并随应用程序一起提供。

因此，不会在运行时进行缓慢的 API 查询，用户可以在没有互联网连接的情况下随时使用该应用。

---

## 2. 系统要求与设置

- **Python 3.10 或更高版本**
- **Git**，需支持子模块
- 安装所需的 Python 包：
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- 初始化 Git 子模块：
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. 数据来源与目录结构

该管道汇集来自多个可信来源的数据：

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
 - 为 Pokémon 主数据、基本统计数据、类型、能力、动作学习集、多语言物种名称和进化提供结构化 JSON 文件。 
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - 德国名字、乐队和角色描述（“所有乐队列表”、“角色”）、性别差异和闪亮的神奇宝贝.
3。 **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**：
 - 全球功能区列表、游戏内交易和所有世代的有毒神奇宝贝（保存为离线 HTML）.
4。 **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - 从关东到 Paldea 和 Z-A.
5 的特定版本礼物和交易的详细列表。 **社区电子表格（`Legal_Matching_Pokeballs.xlsx`）**：
 - 每个版本的所有可捕捉神奇宝贝的详细矩阵以及匹配的神奇球美学。

---

## 4. 快速整体执行（全能运行器）

要使用单个命令按正确顺序运行包含所有脚本的整个管道，请使用 `run_pipeline.py`：

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

这个 Runner 会自动处理：
1. `update_data.py`（更新外部数据和 Git 子模块）
2. `build_database.py`（使用基础数据生成 `assets/db/pokedex.sqlite`）
3. `update_pokemon_languages.py`（同步所有 10 个系列语言的所有物种）
4. `update_evolutions_db.py`（丰富进化树）
5. `update_cap_locks_and_trades.py`（录入帽子、Cosplay & 交易锁）
6. `optimize_databases.py`（创建覆盖索引，`ANALYZE`，`VACUUM`）

---

## 5. 手动流程（单步骤）

如果要手动运行某些脚本：

### 第一步：更新外部原始数据和子模块
```bash
python update_data.py
```
*下载当前的 HTML 缓存，拉取最新的 `Legal_Matching_Pokeballs.xlsx` 并将 `api-data` 子模块更新到最新版本。*

### 步骤 2：构建 SQLite 主数据库
```bash
python tool/data_pipeline/build_database.py
```
*创建 `assets/db/pokedex.sqlite`，读取所有 1,025+ 宝可梦和 250+ 形态，并汇总超过 500 个闪光锁定。*

### 第3步：同步多语言宝可梦名称
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*动态读取所有系列语言自 `lib/i18n/languages.json`，通过 `ALTER TABLE` 添加缺失的列（如 `name_fr`、`name_ja` 等），并从离线 PokeAPI JSON 文件中填充名称。*

### 第4步：丰富开发树
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*计算开发树、分支和触发器。*

### 第5步：录入帽子、角色扮演 & 交换精灵
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*将帽子皮卡丘、角色扮演形态和交换精灵录入 `assets/db/pokedex.sqlite` 和 `database/pokedex.sqlite` 中。*

### 步骤 6：创建索引、优化 & VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*创建覆盖索引，执行 `ANALYZE`、`PRAGMA optimize;` 和 `VACUUM`。*

---

## 6. `pokedex.sqlite` 中的表格概览

|表|描述 |重要索引 |
|---|---|---|
| `口袋妖怪` |所有 1,025 多个神奇宝贝的基本数据，包括 10 个系列语言列（`name_de`、`name_en`、`name_fr`、`name_es`、`name_it`、`name_ja`、`name_ko`、`name_zh_hans`、`name_zh_hant`）| `主键（id）` |
| `表格` |替代形式、Mega、G-Max、区域 | `idx_forms_poke (pokemon_id)` |
| `dex_orders` |区域图鉴订单 | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `special_dexes` |特殊德克斯（例如传奇、超级野兽）| `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` |各版本攻击学习集| `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `口袋妖怪能力` |技能和隐藏能力| `idx_pokemon_bility_poke (pokemon_id)` |
| 「相遇」|地点和遭遇类型 | `idx_encounters_poke (pokemon_id, version_group)` |
| `进化` |完整的开发树 | `主键（species_id）` |
| `丝带` |历代丝带| `主键（id）` |
| `标记` |所有版本的角色| `主键（id）` |
| `闪亮的锁` |所有闪亮锁（全球版和版）| `主键（pokemon_id、form_name、游戏版本）` |
| `合法球` |每个神奇宝贝及版本的合法神奇宝贝球 | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. 验证与质量保证

在每次运行管道之后，必须确保生成的数据库是完整且无错误的：

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

## 8. 路径与开发规范

此目录中的所有脚本都使用动态的、相对的路径解析：
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```

- 绝不要硬编码绝对操作系统路径。
- 不要将临时 JSON 文件放在 `assets/data/` 中；所有静态数据应直接存储在关系型 SQLite 数据库 `assets/db/pokedex.sqlite` 中。

