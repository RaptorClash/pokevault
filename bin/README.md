# PokéVault Database Generation Pipeline (`bin/`)

Dieses Verzeichnis enthält die Offline-Pipeline zur Generierung der SQLite-Referenzdatenbank `assets/db/pokedex.sqlite`.

---

## 1. Voraussetzungen

- **Python 3.10+**
- Python-Bibliotheken:
  ```bash
  pip install beautifulsoup4 openpyxl requests
  ```
- **Git** (für Submodule-Updates in `bin/api-data`)

---

## 2. Datenquellen

Die Pipeline aggregiert Referenzdaten aus mehreren Quellen:

1. **[PokeAPI](https://pokeapi.co/)**:
   - Lokales Git-Submodule in `bin/api-data/` mit vollständigen JSON-Endpoints (Pokémon, Forms, Moves, Abilities, Evolution Chains, Encounters).
2. **[Bulbapedia](https://bulbapedia.bulbagarden.net/)**:
   - Bänder (`List of Ribbons in the games`), In-Game-Trades und Geschenke.
3. **[PokéWiki](https://www.pokewiki.de/)**:
   - Deutsche Übersetzungen, Bänder- & Zeichen-Beschreibungen (`Zeichen`, `Liste aller Bänder`) und Fundorte.
4. **[Bisafans](https://www.bisafans.de/)**:
   - Editionsspezifische Geschenke und Tausche für Kanto bis Paldea und Z-A.
5. **Community Spreadsheet**:
   - `Legal_Matching_Pokeballs.xlsx` für ball-spezifische Fang-Legaltäten aller Generationen.

---

## 3. Ausführung der Pipeline

Führe die Skripte in der folgenden Reihenfolge aus dem Hauptverzeichnis des Repositories aus:

### Schritt 1: Externe Rohdaten & Submodule aktualisieren
```bash
python update_data.py
```
*Lädt alle aktuellen HTML-Seiten herunter, zieht die neueste `Legal_Matching_Pokeballs.xlsx` und bringt das `bin/api-data` Submodul auf den aktuellen Stand.*

### Schritt 2: SQLite-Hauptdatenbank bauen
```bash
python bin/build_database.py
```
*Liest alle JSON- und HTML-Caches ein, normalisiert Namen und Typen, füllt alle Kern-Tabellen und schreibt `assets/db/pokedex.sqlite`.*

### Schritt 3: Evolutionsbäume anreichern
```bash
python bin/update_evolutions_db.py
```
*Extrahiert die PokeAPI-Evolutionsbäume, berechnet Verzweigungen und Anforderungstrigger und aktualisiert die Tabelle `evolutions`.*

---

## 4. Tabellen-Übersicht in `pokedex.sqlite`

| Tabelle | Inhalt | Wichtige Felder |
|---|---|---|
| `pokemon` | Basisdaten aller 1025+ Pokémon | `id`, `name`, `german_name`, `type1`, `type2`, `gen`, `base_stats`, `egg_groups` |
| `forms` | Alternative Formen, Mega, G-Max, Regional | `id`, `pokemon_id`, `form_name`, `form_type`, `is_mega`, `is_gmax` |
| `dex_orders` | Regionale Pokédex-Sortierungen | `dex_name`, `pokemon_id`, `order_index` |
| `pokemon_moves` | Attacken-Learnsets aller Versionen | `pokemon_id`, `move_id`, `version_group`, `learn_method`, `level` |
| `pokemon_abilities` | Fähigkeiten & Versteckte Fähigkeiten | `pokemon_id`, `ability_id`, `is_hidden`, `slot` |
| `encounters` | Fundorte und Begegnungstypen | `pokemon_id`, `version_group`, `location_area`, `method` |
| `evolutions` | Vollständige Entwicklungsbäume | `species_id`, `chain_json` |
| `ribbons` | Bänder aller Generationen | `id`, `name_en`, `name_de`, `description_de`, `gen_available` |
| `marks` | Zeichen (Marks) | `id`, `name_en`, `name_de`, `title_de`, `condition_de` |
| `shiny_categories` | Jagd-Kategorien | `pokemon_id`, `category` |
| `default_levels` | Standard-Level für Fangraten-Berechnung | `pokemon_id`, `default_level` |
| `special_obtainable` | Spezielle Jagd-Methoden | `pokemon_id`, `game`, `method` |
| `legal_balls` | Erlaubte Fangbälle je Pokémon & Edition | `pokemon_id`, `ball_name`, `gen` |
