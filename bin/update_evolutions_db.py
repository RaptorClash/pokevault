"""Updates the evolution chains in pokedex.sqlite from PokeAPI JSON dumps.

Parses JSON data files from `bin/api-data/data/api/v2/evolution-chain/*/index.json`,
extracts triggers, conditions, items, happiness, and relative stats into a structured
tree, and inserts/replaces the serialized JSON in the `evolutions` SQLite table.
"""

import os
import json
import sqlite3
import glob

def parse_chain(node):
    """Recursively parses an evolution chain node from the PokeAPI schema.

    Args:
        node: A dictionary representing an evolution chain node with 'species',
              'evolution_details', and 'evolves_to'.

    Returns:
        A dictionary containing 'species_id', 'is_baby', 'details', and recursive 'evolves_to'.
    """
    species_url = node['species']['url']
    species_id = int(species_url.strip('/').split('/')[-1])
    evolves_to = [parse_chain(n) for n in node.get('evolves_to', [])]
    details = []
    for ed in node.get('evolution_details', []):
        d = {}
        if ed.get('trigger'): d['trigger'] = ed['trigger']['name']
        if ed.get('min_level') is not None: d['min_level'] = ed['min_level']
        if ed.get('item'): d['item'] = ed['item']['name']
        if ed.get('held_item'): d['held_item'] = ed['held_item']['name']
        if ed.get('min_happiness') is not None: d['min_happiness'] = ed['min_happiness']
        if ed.get('min_affection') is not None: d['min_affection'] = ed['min_affection']
        if ed.get('min_beauty') is not None: d['min_beauty'] = ed['min_beauty']
        if ed.get('time_of_day'): d['time_of_day'] = ed['time_of_day']
        if ed.get('known_move'): d['known_move'] = ed['known_move']['name']
        if ed.get('known_move_type'): d['known_move_type'] = ed['known_move_type']['name']
        if ed.get('location'): d['location'] = ed['location']['name']
        if ed.get('gender') is not None: d['gender'] = ed['gender']
        if ed.get('relative_physical_stats') is not None: d['relative_physical_stats'] = ed['relative_physical_stats']
        if ed.get('needs_overworld_rain'): d['needs_overworld_rain'] = ed['needs_overworld_rain']
        if ed.get('turn_upside_down'): d['turn_upside_down'] = ed['turn_upside_down']
        if ed.get('party_species'): d['party_species'] = ed['party_species']['name']
        if ed.get('party_type'): d['party_type'] = ed['party_type']['name']
        if ed.get('trade_species'): d['trade_species'] = ed['trade_species']['name']
        if ed.get('used_move'): d['used_move'] = ed['used_move']['name']
        if ed.get('min_move_count') is not None: d['min_move_count'] = ed['min_move_count']
        if ed.get('min_steps') is not None: d['min_steps'] = ed['min_steps']
        if ed.get('min_damage_taken') is not None: d['min_damage_taken'] = ed['min_damage_taken']
        if ed.get('needs_multiplayer'): d['needs_multiplayer'] = ed['needs_multiplayer']
        if ed.get('near_special_rock'): d['near_special_rock'] = ed['near_special_rock']
        if ed.get('base_form'): d['base_form'] = ed['base_form']['name']
        if ed.get('evolved_form'): d['evolved_form'] = ed['evolved_form']['name']
        if ed.get('region'): d['region'] = ed['region']['name']
        if d not in details:
            details.append(d)
    return {
        'species_id': species_id,
        'is_baby': node.get('is_baby', False),
        'details': details,
        'evolves_to': evolves_to
    }

def main():
    """Scans evolution chain files and updates pokedex.sqlite evolutions table."""
    db_path = 'assets/db/pokedex.sqlite'
    if not os.path.exists(db_path):
        raise FileNotFoundError(f"Database not found at {db_path}")

    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    chain_files = glob.glob('bin/api-data/data/api/v2/evolution-chain/*/index.json')
    print(f"Gefundene Ketten-Dateien: {len(chain_files)}")

    updated = 0
    for file_path in chain_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            chain_id = data.get('id')
            if not chain_id:
                # Fallback aus Pfad
                parts = os.path.normpath(file_path).split(os.sep)
                chain_id = int(parts[-2])
            
            if 'chain' in data and data['chain']:
                parsed = parse_chain(data['chain'])
                c.execute('INSERT OR REPLACE INTO evolutions (chain_id, chain_json) VALUES (?, ?)',
                          (chain_id, json.dumps(parsed)))
                updated += 1
        except Exception as e:
            print(f"Fehler bei {file_path}: {e}")

    conn.commit()
    conn.close()
    print(f"Erfolgreich {updated} Evolutionsketten in {db_path} aktualisiert!")

if __name__ == '__main__':
    main()
