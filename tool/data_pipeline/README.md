# PokéVault Database Generation Pipeline (`tool/data_pipeline/`)

> **Languages:** 🇬🇧 [English](README.md) | 🇩🇪 [Deutsch](README.de.md)

This directory contains the complete offline data pipeline for compiling and optimizing the SQLite reference database `assets/db/pokedex.sqlite` for PokéVault.

---

## 1. Overview & Objectives

PokéVault is built around an **Offline-First** philosophy. All static franchise data (base stats, alternative forms, catch rates, ribbons, marks, move learnsets, encounters, shiny locks, and matching Pokéballs) are pre-aggregated at build time into an SQLite database bundled directly with the application.

This eliminates slow runtime API calls and allows trainers to use PokéVault anywhere without requiring an active internet connection.

---

## 2. Requirements & Setup

- **Python 3.10 or higher**
- **Git** with submodule support
- Install required Python dependencies:
  ```bash
  pip install beautifulsoup4 openpyxl requests
  ```
- Initialize Git submodules:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Data Sources & Directory Structure

The pipeline merges data from several authoritative sources:

```
tool/data_pipeline/
├── run_pipeline.py                 # All-in-One Runner: Executes all steps sequentially
├── build_database.py               # Main compilation script
├── database_constants.py           # Types, generation mappings & ID constants
├── update_evolutions_db.py         # Script for complex evolution trees
├── update_cap_locks_and_trades.py  # Script for cap, cosplay & in-game trade locks
├── optimize_databases.py           # Indexing, PRAGMA ANALYZE & VACUUM
├── api-data/                       # Git submodule: Official PokeAPI JSON dump
├── ribbons_guide/                  # Git submodule: Ribbons.Guide reference
├── Legal_Matching_Pokeballs.xlsx   # Community spreadsheet with legal ball combinations
├── custom_encounters.json          # Manual encounter overrides and additions
├── custom_matching_balls.json      # Manual overrides for recommended matching balls
└── *.html                          # Offline HTML caches (Bulbapedia, PokéWiki, Bisafans)
```

1. **[PokeAPI](https://pokeapi.co/) (`api-data/`)**:
   - Provides structured JSON files for Pokémon base data, stats, types, abilities, moves, and evolutions.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
   - German names, ribbon & mark descriptions, gender differences, and shiny Pokémon.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
   - Global ribbon lists, in-game trades, and gift Pokémon across all generations (stored as offline HTML caches).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
   - Detailed edition-specific gift and trade tables from Kanto to Paldea and Z-A.
5. **Community Spreadsheet (`Legal_Matching_Pokeballs.xlsx`)**:
   - Detailed matrix of all catchable Pokémon per edition and their matching aesthetic Pokéballs.

---

## 4. Quick Execution (All-in-One Runner)

To run the entire pipeline with all scripts in the correct order with a single command, execute `run_pipeline.py`:

```bash
# Run full pipeline (downloads + submodules + DB build + optimization):
python tool/data_pipeline/run_pipeline.py

# Alternatively: Compile & optimize DB only (without re-scraping web data):
python tool/data_pipeline/run_pipeline.py --skip-download
```

This runner automatically handles:
1. `update_data.py` (updates external data & Git submodules)
2. `build_database.py` (generates `assets/db/pokedex.sqlite`)
3. `update_evolutions_db.py` (enriches evolution branching)
4. `update_cap_locks_and_trades.py` (inserts cap Pikachu, cosplay forms & trade locks)
5. `optimize_databases.py` (creates covering indexes, `ANALYZE`, `VACUUM`)

---

## 5. Manual Execution (Step-by-Step)

If individual scripts need to be run separately:

### Step 1: Update external raw data & submodules
```bash
python update_data.py
```
*Downloads fresh HTML caches, fetches the latest `Legal_Matching_Pokeballs.xlsx`, and brings the `api-data` submodule up to date.*

### Step 2: Build main SQLite database
```bash
python tool/data_pipeline/build_database.py
```
*Generates `assets/db/pokedex.sqlite`, parsing all 1,025+ Pokémon and 250+ forms while aggregating over 500 shiny locks.*

### Step 3: Enrich evolution trees
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Computes branching evolution paths, requirements, and triggers.*

### Step 4: Add cap, cosplay & trade locks
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Applies cap Pikachu forms, cosplay variants, and gift/trade locks into `assets/db/pokedex.sqlite` and `database/pokedex.sqlite`.*

### Step 5: Create indexes, optimize & VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Creates covering indexes, executes `ANALYZE`, `PRAGMA optimize;`, and `VACUUM`.*

---

## 6. Table Overview in `pokedex.sqlite`

| Table | Description | Key Indexes |
|---|---|---|
| `pokemon` | Core stats and data for all 1,025+ Pokémon | `PRIMARY KEY (id)` |
| `forms` | Alternative, Mega, G-Max, and Regional forms | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Regional Pokédex ordering | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `special_dexes` | Special categorization (e.g. Legendary, Ultra Beasts) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` | Move learnsets across all version groups | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `pokemon_abilities` | Standard and hidden abilities | `idx_pokemon_abilities_poke (pokemon_id)` |
| `encounters` | In-game encounter locations and methods | `idx_encounters_poke (pokemon_id, version_group)` |
| `evolutions` | Complete evolution chain hierarchies | `PRIMARY KEY (species_id)` |
| `ribbons` | Ribbons across all generations | `PRIMARY KEY (id)` |
| `marks` | Marks across all mainline games | `PRIMARY KEY (id)` |
| `shiny_locks` | All global and game-specific shiny locks | `PRIMARY KEY (pokemon_id, form_name, game_version)` |
| `legal_balls` | Legal Pokéballs per Pokémon and edition | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Verification & Quality Assurance

After running the pipeline, verify that the compiled database is complete and passes all tests:

```powershell
# 1. Run database-specific tests
flutter test test/db/

# 2. Run Shiny Lock tests
flutter test test/services/shiny_lock_service_test.dart
flutter test test/screens/pokemon_info/shiny_lock_ui_test.dart

# 3. Run Catch Rate & Matching Ball tests
flutter test test/screens/pokemon_info/catch_rate_calculator_test.dart
```

---

## 8. Path & Development Conventions

All scripts in this directory resolve paths dynamically:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Never hardcode absolute operating system paths.
- Do not store temporary JSON files in `assets/data/`; all static data belongs in the relational SQLite database `assets/db/pokedex.sqlite`.
