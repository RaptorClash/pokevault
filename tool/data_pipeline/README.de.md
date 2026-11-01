# PokéVault Datenbank-Generierungs-Pipeline (`tool/data_pipeline/`)

> **Sprachen:** 🇬🇧 [English](README.md) | 🇩🇪 [Deutsch](README.de.md)

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
├── run_pipeline.py                 # All-in-One Runner: Führt alle Schritte nacheinander aus
├── build_database.py               # Hauptskript zur Datenbank-Kompilierung
├── database_constants.py           # Typen, Generationen-Mappings & ID-Konstanten
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
   - Bereitstellung strukturierter JSON-Dateien für Pokémon-Stammdaten, Basiswerte, Typen, Fähigkeiten, Attacken-Learnsets und Entwicklungen.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
   - Deutsche Namen, Bänder- & Zeichenbeschreibungen (`Liste aller Bänder`, `Zeichen`), Geschlechtsunterschiede und Schillernde Pokémon.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
   - Globale Bänder-Listen, In-Game-Trades und Gift-Pokémon über alle Generationen (als Offline-HTML gesichert).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
   - Detaillierte Listen editionsspezifischer Geschenke und Tausche von Kanto bis Paldea und Z-A.
5. **Community Spreadsheet (`Legal_Matching_Pokeballs.xlsx`)**:
   - Detaillierte Matrix aller fangbaren Pokémon je Edition und passender Pokéball-Ästhetik.

---

## 4. Schnelle Gesamtausführung (All-in-One Runner)

Um die gesamte Pipeline mit allen Skripten in der korrekten Reihenfolge mit einem einzigen Befehl auszuführen, nutze `run_pipeline.py`:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Dieser Runner kümmert sich automatisch um:
1. `update_data.py` (externe Daten & Git-Submodule aktualisieren)
2. `build_database.py` (`assets/db/pokedex.sqlite` generieren)
3. `update_evolutions_db.py` (Evolutionsbäume anreichern)
4. `update_cap_locks_and_trades.py` (Kappen-, Cosplay- & Tausch-Locks einpflegen)
5. `optimize_databases.py` (Covering-Indizes erstellen, `ANALYZE`, `VACUUM`)

---

## 5. Manueller Ablauf (Einzelschritte)

Falls einzelne Skripte manuell ausgeführt werden sollen:

### Schritt 1: Externe Rohdaten & Submodule aktualisieren
```bash
python update_data.py
```
*Lädt aktuelle HTML-Caches herunter, zieht die neueste `Legal_Matching_Pokeballs.xlsx` und bringt das `api-data` Submodul auf den neuesten Stand.*

### Schritt 2: SQLite-Hauptdatenbank bauen
```bash
python tool/data_pipeline/build_database.py
```
*Erstellt `assets/db/pokedex.sqlite`, liest alle 1.025+ Pokémon und 250+ Formen ein und aggregiert über 500 Shiny-Locks.*

### Schritt 3: Entwicklungsbäume anreichern
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Berechnet Entwicklungsbäume, Verzweigungen und Auslöser.*

### Schritt 4: Kappen-, Cosplay- & Tausch-Locks einpflegen
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Pflegt Kappen-Pikachu, Cosplay-Formen und Tausche in `assets/db/pokedex.sqlite` und `database/pokedex.sqlite` ein.*

### Schritt 5: Indizes erstellen, Optimieren & VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Erstellt Covering-Indizes, führt `ANALYZE`, `PRAGMA optimize;` und `VACUUM` aus.*

---

## 6. Tabellen-Übersicht in `pokedex.sqlite`

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

## 7. Verifikation & Qualitätssicherung

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

## 8. Pfad- & Entwicklungskonventionen

Alle Skripte in diesem Verzeichnis nutzen dynamische, relative Pfadauflösung:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Niemals absolute Betriebssystem-Pfade hardcoden.
- Keine temporären JSON-Dateien in `assets/data/` ablegen; alle statischen Daten gehören direkt in die relationale SQLite-Datenbank `assets/db/pokedex.sqlite`.
