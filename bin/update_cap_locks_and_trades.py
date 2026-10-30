import sqlite3
import json
import os

caps = ['original-cap', 'hoenn-cap', 'sinnoh-cap', 'unova-cap', 'kalos-cap', 'alola-cap', 'world-cap']
cosplay_forms = ['cosplay', 'rock-star', 'belle', 'pop-star', 'phd', 'libre']

for db_path in ['database/pokedex.sqlite', 'assets/db/pokedex.sqlite']:
    if not os.path.exists(db_path):
        continue
    conn = sqlite3.connect(db_path)
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

if os.path.exists('assets/data/shiny_locks.json'):
    with open('assets/data/shiny_locks.json', 'r', encoding='utf-8') as f:
        locks = json.load(f)
    existing_keys = {(l.get('pokemon_id'), l.get('form_name'), l.get('game_version')) for l in locks}
    for cap in caps:
        if (25, cap, 'all') not in existing_keys:
            locks.append({'pokemon_id': 25, 'form_name': cap, 'game_version': 'all', 'lock_type': 'global', 'notes': f"Globaler Shiny-Lock ({cap})"})
    if (25, 'partner-cap', 'Schwert / Schild') not in existing_keys:
        locks.append({'pokemon_id': 25, 'form_name': 'partner-cap', 'game_version': 'Schwert / Schild', 'lock_type': 'edition', 'notes': 'Editions-Lock in SwSh'})
    for cform in cosplay_forms:
        if (25, cform, 'all') not in existing_keys:
            locks.append({'pokemon_id': 25, 'pokemon_name': 'Pikachu', 'form_name': cform, 'game_version': 'all', 'lock_type': 'global', 'notes': f"Globaler Shiny-Lock: Cosplay-Pikachu ({cform}) ist niemals schillernd erhältlich."})
    if (25, 'starter', 'all') not in existing_keys:
        locks.append({'pokemon_id': 25, 'pokemon_name': 'Pikachu', 'form_name': 'starter', 'game_version': 'all', 'lock_type': 'global', 'notes': "Globaler Shiny-Lock: Starter-Pikachu (Let's Go) ist niemals schillernd erhältlich."})
    if (133, 'starter', 'all') not in existing_keys:
        locks.append({'pokemon_id': 133, 'pokemon_name': 'Evoli', 'form_name': 'starter', 'game_version': 'all', 'lock_type': 'global', 'notes': "Globaler Shiny-Lock: Starter-Evoli (Let's Go) ist niemals schillernd erhältlich."})
    with open('assets/data/shiny_locks.json', 'w', encoding='utf-8') as f:
        json.dump(locks, f, ensure_ascii=False, indent=2)
    print("Updated assets/data/shiny_locks.json")
