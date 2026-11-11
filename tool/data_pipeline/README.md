# PokéVault Database Generation Pipeline (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](locales/README.de.md) | **[🇬🇧 English](README.md)** | [🇫🇷 Français](locales/README.fr.md) | [🇪🇸 Español](locales/README.es.md) | [🇮🇹 Italiano](locales/README.it.md) | [🇯🇵 日本語](locales/README.ja.md) | [🇰🇷 한국어](locales/README.ko.md) | [🇨🇳 简体中文](locales/README.zh-hans.md) | [🇹🇼 繁體中文](locales/README.zh-hant.md) | [🇵🇹 Português](locales/README.pt.md) | [🇳🇱 Nederlands](locales/README.nl.md) | [🇵🇱 Polski](locales/README.pl.md) | [🇷🇺 Русский](locales/README.ru.md)

This directory contains the complete offline data pipeline to generate and optimize the SQLite reference database `assets/db/pokedex.sqlite` for PokéVault.

---

## 1. Overview & Objectives

PokéVault operates on an **Offline-First** philosophy. All static franchise data (base stats, alternative forms, catch rates, ribbons, move learnsets, encounters, shiny locks, multi-lingual species names, and matching balls) are pre-aggregated into an optimized SQLite database at build time and shipped with the app.

This eliminates runtime network latency, protects against API downtime or breaking upstream changes, and allows full app functionality without an internet connection.

---

## 2. Requirements & Setup

- **Python 3.10+**
- **Git** with submodule support
- Install required Python packages:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Initialize and sync git submodules:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Data Sources & Directory Structure

The pipeline synthesizes data from multiple trusted community and official sources:

```text
tool/data_pipeline/
├── run_pipeline.py                 # All-in-One Runner: Executes all scripts sequentially
├── build_database.py               # Core database compiler script
├── database_constants.py           # Types, generation mappings & ID constants
├── update_pokemon_languages.py     # Synchronizes multi-lingual species names from PokeAPI
├── update_evolutions_db.py         # Evolution tree resolution script
├── update_cap_locks_and_trades.py  # In-game trades and cap/cosplay shiny locks
├── optimize_databases.py           # Index creation, PRAGMA ANALYZE & VACUUM
├── api-data/                       # Git submodule: Official PokeAPI JSON dump
├── ribbons_guide/                  # Git submodule: Ribbons.Guide reference data
├── Legal_Matching_Pokeballs.xlsx   # Community-curated legal ball combinations
├── custom_encounters.json          # Manual encounter additions and overrides
├── custom_matching_balls.json      # Manual ball aesthetics overrides
└── *.html                          # Offline HTML caches (Bulbapedia, PokéWiki, Bisafans)
```

1. **[PokeAPI](https://pokeapi.co/) (`api-data/`)**:
   - Structured JSON files for species core data, base stats, forms, types, abilities, moves, multi-lingual names, and evolution chains.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
   - German names, ribbon and mark descriptions, gender differences, and shiny mechanics.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
   - Comprehensive historical ribbon lists, in-game trades, and gift Pokémon across generations.
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
   - Game-specific gifts and in-game trades from Kanto through Paldea and Z-A.
5. **Community Spreadsheet (`Legal_Matching_Pokeballs.xlsx`)**:
   - Catchable Pokémon matrix per edition and matching ball aesthetics.

---

## 4. End-to-End Pipeline Execution (All-in-One Runner)

To execute the entire pipeline in sequence with a single command, run `run_pipeline.py`:

```bash
# Full pipeline (Scrapers + Submodules + DB Build + Multi-Language + Optimization):
python tool/data_pipeline/run_pipeline.py

# Offline compilation only (skip web downloads / re-scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

The runner automatically coordinates:
1. `update_data.py` (external assets and submodule sync)
2. `build_database.py` (generates `assets/db/pokedex.sqlite`)
3. `update_pokemon_languages.py` (syncs all 10 official franchise languages for all species)
4. `update_evolutions_db.py` (enriches evolution chains)
5. `update_cap_locks_and_trades.py` (injects trade and special form locks)
6. `optimize_databases.py` (creates covering indexes, runs `ANALYZE`, `PRAGMA optimize;`, `VACUUM`)

---

## 5. Manual Execution Steps

If you need to run individual pipeline steps:

### Step 1: Sync Raw External Data & Submodules
```bash
python update_data.py
```

### Step 2: Compile Core Database
```bash
python tool/data_pipeline/build_database.py
```

### Step 3: Synchronize Multi-Language Pokémon Names
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Dynamically reads franchise languages from `lib/i18n/languages.json`, alters `pokedex.sqlite` with missing language columns (`name_fr`, `name_ja`, etc.), and populates localized names from PokeAPI.*

### Step 4: Enrich Evolution Chains
```bash
python tool/data_pipeline/update_evolutions_db.py
```

### Step 5: Inject Locks & Trades
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```

### Step 6: Create Covering Indexes & Optimize
```bash
python tool/data_pipeline/optimize_databases.py
```

---

## 6. Database Schema Overview (`pokedex.sqlite`)

| Table | Description | Key Indexes |
|---|---|---|
| `pokemon` | Core species data for 1,025+ Pokémon including 10 franchise language columns (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `PRIMARY KEY (id)` |
| `forms` | Alternative, Regional, Mega, G-Max forms | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Regional Pokédex ordering mappings | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `special_dexes` | Special groupings (Legendary, Ultra Beasts, etc.) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` | Complete learnsets across version groups | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `pokemon_abilities` | Abilities and hidden abilities | `idx_pokemon_abilities_poke (pokemon_id)` |
| `encounters` | In-game encounters and location types | `idx_encounters_poke (pokemon_id, version_group)` |
| `evolutions` | Recursive evolution chains | `PRIMARY KEY (species_id)` |
| `ribbons` | Ribbons across all generations | `PRIMARY KEY (id)` |
| `marks` | Marks across all generations | `PRIMARY KEY (id)` |
| `shiny_locks` | Granular shiny locks per game and form | `PRIMARY KEY (pokemon_id, form_name, game_version)` |
| `legal_balls` | Legal Pokéball matrix per generation | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Verification & Quality Assurance

After running the pipeline, ensure the generated database satisfies all test invariants:

```powershell
flutter test test/database/
flutter test test/db/
flutter test test/services/shiny_lock_service_test.dart
flutter test test/screens/pokemon_info/catch_rate_calculator_test.dart
```

---

## 8. Path & Coding Conventions

All pipeline scripts utilize relative path resolution via `pathlib.Path`:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Never hardcode absolute system paths.
- All static reference data must reside in `assets/db/pokedex.sqlite`.
