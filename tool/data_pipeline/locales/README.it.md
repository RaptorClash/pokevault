# Pipeline di generazione del database di PokéVault (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | **[🇮🇹 Italiano](README.it.md)** | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Questa directory contiene l'intera pipeline di dati offline per la creazione e l'ottimizzazione del database di riferimento SQLite `assets/db/pokedex.sqlite` per PokéVault.

---

## 1. Panoramica e obiettivi

PokéVault funziona secondo un principio **Offline-First**. Tutti i dati statici del franchise (valori base dei Pokémon, forme alternative, tassi di cattura, nastri, set di apprendimento delle mosse, luoghi di ritrovamento, Shiny-Locks, nomi delle specie in più lingue e Poké Ball corrispondenti) vengono pre-aggregati in un database SQLite al momento della compilazione e distribuiti con l'app.

In questo modo vengono eliminate le interrogazioni API lente durante l'esecuzione e gli utenti possono utilizzare l'app ovunque senza connessione a Internet.

---

## 2. Requisiti di sistema & Configurazione

- **Python 3.10 o superiore**
- **Git** con supporto per i sottomoduli
- Installare i pacchetti Python necessari:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Inizializzare i sottomoduli Git:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Fonti dei dati & Struttura delle directory

La pipeline unisce dati provenienti da più fonti affidabili:

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
 - Fornisci file JSON strutturati per dati master Pokémon, statistiche di base, tipi, abilità, set di apprendimento delle mosse, nomi di specie multilingue ed evoluzioni.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - Nomi tedeschi, gruppi e descrizioni dei personaggi ("elenco di tutti i gruppi", "personaggi"), differenze di genere e Pokémon lucenti.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 - Elenchi di nastri globali, scambi in-game e Pokémon velenosi di tutte le generazioni (salvati come HTML offline).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - Elenchi dettagliati di regali e scambi specifici dell'edizione da Kanto a Paldea e Z-A.
5. **Foglio di calcolo della comunità (`Legal_Matching_Pokeballs.xlsx`)**:
 - Matrice dettagliata di tutti i Pokémon catturabili per edizione e estetica Pokéball corrispondente.

---

## 4. Esecuzione rapida complessiva (Runner tutto-in-uno)

Per eseguire l'intera pipeline con tutti gli script nell'ordine corretto con un unico comando, utilizza `run_pipeline.py`:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Questo Runner si occupa automaticamente di:
1. `update_data.py` (aggiornare dati esterni e sottosistemi Git)
2. `build_database.py` (generare `assets/db/pokedex.sqlite` con dati di base)
3. `update_pokemon_languages.py` (sincronizzare tutte e 10 le lingue del franchise per tutte le specie)
4. `update_evolutions_db.py` (arricchire gli alberi evolutivi)
5. `update_cap_locks_and_trades.py` (inserire blocchi per cappelli, cosplay e scambi)
6. `optimize_databases.py` (creare indici di copertura, `ANALYZE`, `VACUUM`)

---

## 5. Procedura manuale (passaggi individuali)

Se alcuni script devono essere eseguiti manualmente:

### Passo 1: Aggiornare i dati grezzi esterni e i sottomoduli
```bash
python update_data.py
```
*Scarica le cache HTML correnti, recupera l'ultima `Legal_Matching_Pokeballs.xlsx` e aggiorna il sottomodulo `api-data` all'ultima versione.*

### Passo 2: Costruire il database principale SQLite
```bash
python tool/data_pipeline/build_database.py
```
*Crea `assets/db/pokedex.sqlite`, legge tutti i 1.025+ Pokémon e 250+ forme e aggrega oltre 500 blocchi Shiny.*

### Passaggio 3: Sincronizzare i nomi dei Pokémon multilingue
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Legge dinamicamente tutte le lingue del franchise da `lib/i18n/languages.json`, aggiunge le colonne mancanti (`name_fr`, `name_ja`, ecc.) tramite `ALTER TABLE` e riempie i nomi dai JSON offline di PokeAPI.*

### Passaggio 4: Arricchire gli alberi di sviluppo
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Calcola alberi di sviluppo, ramificazioni e trigger.*

### Passo 5: Inserire cappelli, cosplay e scambi
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Inserisce Pikachu con cappello, forme cosplay e scambi in `assets/db/pokedex.sqlite` e `database/pokedex.sqlite`.*

### Passaggio 6: Creare indici, ottimizzare e VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Crea indici di copertura, esegue `ANALYZE`, `PRAGMA optimize;` e `VACUUM`.*

---

## 6. Panoramica delle tabelle in `pokedex.sqlite`

| Tabella | Descrizione | Indici importanti |
|---|---|---|
| `Pokemon` | Dati di base per tutti gli oltre 1.025 Pokémon, incluse 10 colonne della lingua del franchise (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | "CHIAVE PRIMARIA (id)" |
| `forme` | Forme alternative, Mega, G-Max, Regionale | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Ordini Pokédex regionali | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `dex_speciali` | Dex speciali (ad es. Leggendari, Ultracreature) | `idx_special_dexes_poke_dex (id_pokemon, nome_dex)` |
| `pokemon_mosse` | Insiemi di apprendimento di attacco di tutte le versioni | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `pokemon_abilities` | Abilità e abilità nascoste | `idx_pokemon_abilities_poke (pokemon_id)` |
| `incontri` | Luoghi e tipi di incontro | `idx_encounters_poke (pokemon_id, version_group)` |
| `evoluzione` | Alberi di sviluppo completi | `CHIAVE PRIMARIA (id_specie)` |
| `nastri` | Nastri di tutte le generazioni | "CHIAVE PRIMARIA (id)" |
| "segna" | Personaggi di tutte le edizioni | "CHIAVE PRIMARIA (id)" |
| `lucchetti_lucenti` | Tutte le serrature lucenti (globale ed edizione) | `CHIAVE PRIMARIA (id_pokemon, nome_modulo, versione_gioco)` |
| `palle_legali` | Poké Ball legali per Pokémon ed edizione | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Verifica e assicurazione della qualità

Dopo ogni esecuzione della pipeline, bisogna assicurarsi che il database generato sia completo e privo di errori:

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

## 8. Convenzioni di percorso e di sviluppo

Tutti gli script in questa directory utilizzano la risoluzione dinamica e relativa dei percorsi:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Mai scrivere hardcoded percorsi assoluti del sistema operativo.
- Non collocare file JSON temporanei in `assets/data/`; tutti i dati statici devono andare direttamente nel database relazionale SQLite `assets/db/pokedex.sqlite`.
