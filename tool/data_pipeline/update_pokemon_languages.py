#!/usr/bin/env python3
"""Updates pokedex.sqlite with multi-language names from offline PokeAPI dumps.

Fully automated & dynamic:
- Reads franchise languages dynamically from lib/i18n/languages.json.
- Adds missing name_<lang> columns to the SQLite database automatically.
- Automatically discovers all available Pokemon species IDs from the submodule or database.
"""

import json
import sqlite3
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
API_DATA_DIR = REPO_ROOT / "tool" / "data_pipeline" / "api-data" / "data" / "api" / "v2"
ASSETS_DB_PATH = REPO_ROOT / "assets" / "db" / "pokedex.sqlite"
DEV_DB_PATH = REPO_ROOT / "database" / "pokedex.sqlite"
LANGUAGES_JSON_PATH = REPO_ROOT / "lib" / "i18n" / "languages.json"

def load_franchise_languages():
    """Loads franchise languages configured in languages.json."""
    if not LANGUAGES_JSON_PATH.exists():
        return [
            {"code": "de", "col": "name_de"},
            {"code": "en", "col": "name_en"},
            {"code": "fr", "col": "name_fr"},
            {"code": "es", "col": "name_es"},
            {"code": "it", "col": "name_it"},
            {"code": "ja", "col": "name_ja"},
            {"code": "ko", "col": "name_ko"},
            {"code": "zh-Hans", "col": "name_zh_hans"},
            {"code": "zh-Hant", "col": "name_zh_hant"},
        ]

    with open(LANGUAGES_JSON_PATH, "r", encoding="utf-8") as f:
        langs = json.load(f)

    result = []
    for l in langs:
        if l.get("isPokemonFranchise", False):
            code = l["code"]
            col = f"name_{code.lower().replace('-', '_')}"
            result.append({"code": code, "col": col})
    return result

def add_columns_if_missing(conn, franchise_languages):
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(pokemon)")
    existing_cols = {row[1] for row in cur.fetchall()}

    for item in franchise_languages:
        col_name = item["col"]
        if col_name not in existing_cols:
            print(f"Adding column {col_name} TEXT to pokemon table...")
            cur.execute(f"ALTER TABLE pokemon ADD COLUMN {col_name} TEXT")
    conn.commit()

def update_database(db_path):
    if not db_path.exists():
        print(f"Database {db_path} does not exist, skipping.")
        return

    franchise_languages = load_franchise_languages()
    print(f"Updating multi-language Pokemon names in: {db_path}")
    print(f"Detected franchise languages ({len(franchise_languages)}): {[l['code'] for l in franchise_languages]}")

    conn = sqlite3.connect(db_path)
    add_columns_if_missing(conn, franchise_languages)

    cur = conn.cursor()
    species_dir = API_DATA_DIR / "pokemon-species"

    # Dynamically discover all Pokemon IDs
    if species_dir.exists():
        poke_ids = sorted([int(p.name) for p in species_dir.iterdir() if p.is_dir() and p.name.isdigit()])
    else:
        cur.execute("SELECT id FROM pokemon ORDER BY id ASC")
        poke_ids = [row[0] for row in cur.fetchall()]

    if not poke_ids:
        poke_ids = list(range(1, 1026))

    print(f"Processing {len(poke_ids)} Pokemon species...")

    count = 0
    for poke_id in poke_ids:
        json_file = species_dir / str(poke_id) / "index.json"
        if not json_file.exists():
            continue

        try:
            with open(json_file, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            print(f"Error loading {json_file}: {e}")
            continue

        names = data.get("names", [])
        
        # Build map of normalized language -> name
        name_map = {}
        for n in names:
            lang = n.get("language", {}).get("name", "").lower().replace("_", "-")
            val = n.get("name", "")
            if val:
                name_map[lang] = val

        # Resolve for each franchise language
        col_values = []
        set_clauses = []
        for l in franchise_languages:
            code_norm = l["code"].lower().replace("_", "-")
            val = name_map.get(code_norm)
            if not val and code_norm == "ja":
                val = name_map.get("ja-hrkt")
            col_values.append(val)
            set_clauses.append(f"{l['col']} = ?")

        col_values.append(poke_id)
        sql = f"UPDATE pokemon SET {', '.join(set_clauses)} WHERE id = ?"
        cur.execute(sql, col_values)
        count += 1

    conn.commit()
    conn.close()
    print(f"Successfully updated {count} Pokemon entries in {db_path}!")

def main():
    update_database(ASSETS_DB_PATH)
    if DEV_DB_PATH.exists():
        update_database(DEV_DB_PATH)

if __name__ == "__main__":
    main()
