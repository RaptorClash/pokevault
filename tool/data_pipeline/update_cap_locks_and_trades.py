import sqlite3
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent


def main():
    caps = ['original-cap', 'hoenn-cap', 'sinnoh-cap', 'unova-cap', 'kalos-cap', 'alola-cap', 'world-cap']
    cosplay_forms = ['cosplay', 'rock-star', 'belle', 'pop-star', 'phd', 'libre']

    for db_path in [REPO_ROOT / 'database' / 'pokedex.sqlite', REPO_ROOT / 'assets' / 'db' / 'pokedex.sqlite']:
        if not db_path.exists():
            continue
        conn = sqlite3.connect(str(db_path))
        c = conn.cursor()
        c.execute("UPDATE special_obtainable SET form = 'alola' WHERE obtain_type = 'trade' AND (game_version LIKE '%let%go%' OR notes LIKE '%let%go%')")
        for cap in caps:
            c.execute("INSERT OR REPLACE INTO shiny_locks (pokemon_id, form_name, game_version, lock_type, notes) VALUES (25, ?, 'all', 'global', ?)", (cap, f"Pikachu mit Kappe ({cap}) ist niemals schillernd."))
        c.execute("INSERT OR REPLACE INTO shiny_locks (pokemon_id, form_name, game_version, lock_type, notes) VALUES (25, 'partner-cap', 'Schwert / Schild', 'edition', 'In Schwert/Schild schillernd gesperrt.')")

        # Update or insert Cosplay Pikachu forms
        c.execute("DELETE FROM shiny_locks WHERE pokemon_id = 25 AND form_name = 'cosplay'")
        for cform in cosplay_forms:
            c.execute("INSERT OR REPLACE INTO shiny_locks (pokemon_id, form_name, game_version, lock_type, notes) VALUES (25, ?, 'all', 'global', ?)", (cform, f"Globaler Shiny-Lock: Cosplay-Pikachu ({cform}) ist niemals schillernd erhältlich."))

        # Insert Starter Pikachu and Starter Eevee
        c.execute("INSERT OR REPLACE INTO shiny_locks (pokemon_id, form_name, game_version, lock_type, notes) VALUES (25, 'starter', 'all', 'global', ?)", ("Globaler Shiny-Lock: Starter-Pikachu (Let's Go) ist niemals schillernd erhältlich.",))
        c.execute("INSERT OR REPLACE INTO shiny_locks (pokemon_id, form_name, game_version, lock_type, notes) VALUES (133, 'starter', 'all', 'global', ?)", ("Globaler Shiny-Lock: Starter-Evoli (Let's Go) ist niemals schillernd erhältlich.",))

        conn.commit()
        conn.close()
        print(f"Updated {db_path}")


if __name__ == '__main__':
    main()
