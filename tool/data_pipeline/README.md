# PokéVault Database Generation Pipeline (`tool/data_pipeline/`)

Dieses Verzeichnis enthält die vollständige Offline-Daten-Pipeline zur Erstellung und Optimierung der SQLite-Referenzdatenbank `assets/db/pokedex.sqlite` für PokéVault.

---

## 1. Übersicht & Zielsetzung

PokéVault arbeitet nach einem **Offline-First**-Prinzip. Alle statischen Franchise-Daten (Pokémon-Basiswerte, alternative Formen, Fangraten, Bänder, Attacken-Learnsets, Fundorte, Shiny-Locks und passende Bälle) werden zur Build-Zeit in einer SQLite-Datenbank voraggregiert und mit der App ausgeliefert.

Dadurch entfallen langsame API-Abfragen zur Laufzeit und Nutzer können die App überall ohne Internetverbindung verwenden.

---

## 2. Systemanforderungen & Setup

- **Python 3.10 oder höher**
- **Git** mit Submodul-Unterstützung
- Erforderliche Python-Pakete installieren:
  ```bash
  pip install beautifulsoup4 openpyxl requests
  ```
- Git-Submodule initialisieren:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Datenquellen & Verzeichnisstruktur

Die Pipeline führt Daten aus mehreren vertrauenswürdigen Quellen zusammen:

```
tool/data_pipeline/
├── api-data/                       # Git-Submodul: Offizieller PokeAPI JSON-Dump
├── ribbons_guide/                  # Git-Submodul: Ribbons.Guide Referenz
├── Legal_Matching_Pokeballs.xlsx   # Community-Excel mit legalen Ball-Kombinationen
├── custom_encounters.json          # Manuelle Ergänzungen für Fundorte
├── custom_matching_balls.json      # Manuelle Overrides für empfohlene Bälle
├── build_database.py               # Hauptskript zur Datenbank-Kompilierung
├── database_constants.py           # Typen, Generationen-Mappings & ID-Konstanten
├── update_evolutions_db.py         # Skript für komplexe Entwicklungsbäume
├── update_cap_locks_and_trades.py  # Skript für Kappen-, Cosplay- & Tausch-Locks
├── optimize_databases.py           # Indexierung, PRAGMA ANALYZE & VACUUM
└── *.html                          # Offline HTML-Caches (Bulbapedia, PokéWiki, Bisafans)
```

1. **[PokeAPI](https://pokeapi.co/) (`api-data/`)**:
   - Bereitstellung strukturierter JSON-Dateien für Pokémon-Stammdaten, Basiswerte, Typen, Fähigkeiten, Attacken-Learnsets und Entwicklungen.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
   - Deutsche Namen, Bänder- & Zeichenbeschreibungen (`Liste aller Bänder`, `Zeichen`), Geschlechtsunterschiede und Schillernde Pokémon.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
   - Globale Bänder-Listen, In-Game-Trades und Gift-Pokémon über alle Generationen.
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
   - Detaillierte Listen editionsspezifischer Geschenke und Tausche von Kanto bis Paldea und Z-A.
5. **Community Spreadsheet (`Legal_Matching_Pokeballs.xlsx`)**:
   - Detaillierte Matrix aller fangbaren Pokémon je Edition und passender Pokéball-Ästhetik.

---

## 4. Vollständiger Ablauf der Pipeline (Step-by-Step)

Die Pipeline wird in einer fest definierten Reihenfolge aus dem Hauptverzeichnis des Repositories ausgeführt:

### Schritt 1: Externe Rohdaten & Submodule aktualisieren
```bash
python update_data.py
```
*Was passiert:*
- Aktualisiert das PokeAPI Submodul (`tool/data_pipeline/api-data`).
- Lädt die neueste `Legal_Matching_Pokeballs.xlsx` herunter.
- Aktualisiert HTML-Dumps von Bulbapedia, PokéWiki und Bisafans im Cache.

---

### Schritt 2: SQLite-Hauptdatenbank bauen
```bash
python tool/data_pipeline/build_database.py
```
*Was passiert:*
- Erstellt das Schema der SQLite-Datenbank `assets/db/pokedex.sqlite`.
- Liest alle 1.025+ Pokémon und über 250+ alternative Formen (Mega, Gigadynamax, Regionalformen, Spezialformen).
- Füllt Dex-Sortierungen (`dex_orders`), Attacken (`pokemon_moves`), Fähigkeiten (`pokemon_abilities`) und Bänder (`ribbons`, `marks`).
- Aggregiert alle **Shiny-Locks** (über 500 Einträge für globale, editions- und event-spezifische Sperren) direkt in die Tabelle `shiny_locks`.

---

### Schritt 3: Entwicklungsbäume anreichern
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Was passiert:*
- Verarbeitet die verschachtelten Evolution-Chains aus dem PokeAPI-Submodul.
- Berechnet Verzweigungen (z. B. Evoli, Rabauz, Wutanfall-Bedingungen) und Auslöser (Items, Level, Tageszeit, Zuneigung, Tausch).
- Schreibt normalisierte Daten in die Tabelle `evolutions`.

---

### Schritt 4: Kappen-, Cosplay- & Tausch-Locks einpflegen
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Was passiert:*
- Trägt spezifische Shiny-Locks für Kappen-Pikachu, Cosplay-Pikachu, Let's Go Starter und Alola-Tausche nach.
- Synchronisiert sowohl `assets/db/pokedex.sqlite` als auch die lokale Entwickler-Datenbank `database/pokedex.sqlite`.

---

### Schritt 5: Indizes erstellen, Optimieren & VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Was passiert:*
- Erstellt hochperformante Covering-Indizes (z. B. `idx_dex_orders_poke_dex` auf `(pokemon_id, dex_name, order_index)`).
- Führt `ANALYZE` und `PRAGMA optimize;` aus, um die SQLite Query-Planner-Statistiken zu berechnen.
- Führt `PRAGMA integrity_check` durch.
- Kompaktiert die Datenbankdatei via `VACUUM` auf minimale Dateigröße.

---

## 5. Tabellen-Übersicht in `pokedex.sqlite`

| Tabelle | Beschreibung | Wichtige Indizes |
|---|---|---|
| `pokemon` | Basisdaten aller 1.025+ Pokémon | `PRIMARY KEY (id)` |
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

## 6. Verifikation & Qualitätssicherung

Nach jeder Ausführung der Pipeline muss sichergestellt werden, dass die generierte Datenbank vollständig und fehlerfrei ist:

```powershell
# 1. Datenbank-spezifische Tests ausführen
flutter test test/db/

# 2. Shiny-Lock Tests ausführen
flutter test test/services/shiny_lock_service_test.dart
flutter test test/screens/pokemon_info/shiny_lock_ui_test.dart

# 3. Fangraten- & Matching-Ball Tests
flutter test test/screens/pokemon_info/catch_rate_calculator_test.dart
```

---

## 7. Pfad- & Entwicklungskonventionen

Alle Skripte in diesem Verzeichnis nutzen dynamische, relative Pfadauflösung:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Niemals absolute Betriebssystem-Pfade hardcoden.
- Keine temporären JSON-Dateien in `assets/data/` ablegen; alle statischen Daten gehören direkt in die relationale SQLite-Datenbank `assets/db/pokedex.sqlite`.
