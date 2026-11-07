# PokéVault databasegeneratie-pijplijn (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | **[🇳🇱 Nederlands](README.nl.md)** | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Deze map bevat de volledige offline datapijplijn voor het aanmaken en optimaliseren van de SQLite-referencedatabase `assets/db/pokedex.sqlite` voor PokéVault.

---

## 1. Overzicht & Doelstelling

PokéVault werkt volgens een **Offline-First**-principe. Alle statische franchisegegevens (Pokémon-basiswaarden, alternatieve vormen, vangstpercentages, linten, aanval-leersets, locaties, Shiny-locks, meertalige soortennamen en bijpassende ballen) worden tijdens het bouwen vooraf geaggregeerd in een SQLite-database en met de app meegeleverd.

Daardoor vervallen trage API-aanvragen tijdens de uitvoering en kunnen gebruikers de app overal zonder internetverbinding gebruiken.

---

## 2. Systeemvereisten & Setup

- **Python 3.10 of hoger**
- **Git** met submodule-ondersteuning
- Vereiste Python-pakketten installeren:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Git-submodules initialiseren:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Gegevensbronnen & Mapstructuur

De pijplijn brengt gegevens uit meerdere betrouwbare bronnen samen:

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
 - Bied gestructureerde JSON-bestanden voor Pokémon-mastergegevens, basisstatistieken, typen, vaardigheden, leersets voor bewegingen, meertalige soortnamen en evoluties.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - Duitse namen, bands en karakterbeschrijvingen ('lijst van alle bands', 'karakters'), geslachtsverschillen en glimmende Pokémon.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 - Globale lintlijsten, in-game transacties en Poison Pokémon voor alle generaties (opgeslagen als offline HTML).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - Gedetailleerde lijsten met editie-specifieke geschenken en transacties van Kanto tot Paldea en Z-A.
5. **Community Spreadsheet (`Legal_Matching_Pokeballs.xlsx`)**:
 - Gedetailleerde matrix van alle vangbare Pokémon per editie en bijpassende Pokéball-esthetiek.

---

## 4. Snelle algehele uitvoering (All-in-One Runner)

Om de gehele pijplijn met alle scripts in de juiste volgorde met één enkel commando uit te voeren, gebruik `run_pipeline.py`:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Deze Runner zorgt automatisch voor:
1. `update_data.py` (externe gegevens en Git-submodules bijwerken)
2. `build_database.py` (`assets/db/pokedex.sqlite` genereren met basisgegevens)
3. `update_pokemon_languages.py` (synchroniseert alle 10 franchise-talen voor alle soorten)
4. `update_evolutions_db.py` (evolutie-bomen verrijken)
5. `update_cap_locks_and_trades.py` (caps-, cosplay- & ruil-locks invoeren)
6. `optimize_databases.py` (covering-indexen aanmaken, `ANALYZE`, `VACUUM`)

---

## 5. Handmatig proces (enkele stappen)

Als bepaalde scripts handmatig uitgevoerd moeten worden:

### Stap 1: Externe ruwe data & submodules bijwerken
```bash
python update_data.py
```
*Downloadt de actuele HTML-caches, haalt de nieuwste `Legal_Matching_Pokeballs.xlsx` op en brengt de `api-data` submodule naar de laatste stand.*

### Stap 2: SQLite-hoofddatabase bouwen
```bash
python tool/data_pipeline/build_database.py
```
*Maakt `assets/db/pokedex.sqlite`, leest alle 1.025+ Pokémon en 250+ vormen en aggregeert meer dan 500 Shiny-locks.*

### Stap 3: Meertalige Pokémon-namen synchroniseren
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Leest alle franchise-talen dynamisch uit `lib/i18n/languages.json`, voegt ontbrekende kolommen (`name_fr`, `name_ja`, enz.) toe via `ALTER TABLE` en vult de namen in vanuit de offline PokeAPI-JSONs.*

### Stap 4: Ontwikkelingsbomen verrijken
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Berekent ontwikkelingsbomen, vertakkingen en triggers.*

### Stap 5: hoed-, cosplay- & ruil-Pokémon invoeren
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Voert hoed-Pikachu, cosplay-vormen en ruils in `assets/db/pokedex.sqlite` en `database/pokedex.sqlite` in.*

### Stap 6: Indexen aanmaken, optimaliseren & VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Maakt dekkende indexen, voert `ANALYZE`, `PRAGMA optimize;` en `VACUUM` uit.*

---

## 6. Tabellenoverzicht in `pokedex.sqlite`

| Tabel | Beschrijving | Belangrijke indexen |
|---|---|---|
| `Pokemon` | Basisgegevens voor alle meer dan 1.025 Pokémon, inclusief 10 franchisetaalkolommen (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `PRIMARY SLEUTEL (id)` |
| `formulieren` | Alternatieve vormen, Mega, G-Max, Regionaal | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Regionale Pokédex-bestellingen | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `speciale_dexes` | Speciale Dexen (bijv. Legendarische, Ultra Beasts) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` | Aanvalleersets van alle versies | `idx_pokemon_moves_poke (pokemon_id, versiegroep)` |
| `pokemon_vaardigheden` ​​| Vaardigheden en verborgen capaciteiten | `idx_pokemon_abilities_poke (pokemon_id)` |
| `ontmoetingen` | Locaties en soorten ontmoetingen | `idx_encounters_poke (pokemon_id, versiegroep)` |
| `evolutie` | Volledige ontwikkelingsbomen | `PRIMARY SLEUTEL (soort_id)` |
| `linten` | Linten van alle generaties | `PRIMARY SLEUTEL (id)` |
| `merken` | Karakters van alle edities | `PRIMARY SLEUTEL (id)` |
| `glimmende_sloten` | Alle glanzende sloten (wereldwijd en editie) | `PRIMARY KEY (Pokemon_id, form_name, game_version)` |
| `legale_ballen` | Legale Poké Balls per Pokémon en editie | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Verificatie & Kwaliteitsborging

Na elke uitvoering van de pijplijn moet worden gegarandeerd dat de gegenereerde database volledig en foutloos is:

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

## 8. Pad- & Ontwikkelingsconventies

Alle scripts in deze map gebruiken dynamische, relatieve padresolutie:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Nooit absolute besturingssysteempaden hardcoden.
- Geen tijdelijke JSON-bestanden opslaan in `assets/data/`; alle statische gegevens horen rechtstreeks in de relationele SQLite-database `assets/db/pokedex.sqlite`.
