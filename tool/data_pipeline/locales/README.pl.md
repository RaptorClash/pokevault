# Pipeline generowania bazy danych PokéVault (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | **[🇵🇱 Polski](README.pl.md)** | [🇷🇺 Русский](README.ru.md)

Ten katalog zawiera kompletną offline’ową procedurę przetwarzania danych do tworzenia i optymalizacji referencyjnej bazy danych SQLite `assets/db/pokedex.sqlite` dla PokéVault.

---

## 1. Przegląd i cele

PokéVault działa zgodnie z zasadą **Offline-First**. Wszystkie statyczne dane franczyzowe (wartości bazowe Pokémonów, alternatywne formy, współczynniki łapania, wstążki, zestawy nauki ataków, miejsca pojawiania się, blokady Shiny, wielojęzyczne nazwy gatunków i odpowiednie Pokeballe) są wstępnie agregowane do bazy danych SQLite w czasie budowania i dostarczane z aplikacją.

Dzięki temu eliminowane są wolne zapytania API w czasie działania, a użytkownicy mogą korzystać z aplikacji wszędzie bez połączenia z Internetem.

---

## 2. Wymagania systemowe i konfiguracja

- **Python 3.10 lub nowszy**
- **Git** z obsługą submodułów
- Zainstaluj wymagane pakiety Pythona:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Zainicjuj submoduły Git:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Źródła danych i struktura katalogów

Rurociąg łączy dane z kilku wiarygodnych źródeł:

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
 - Zapewnia ustrukturyzowane pliki JSON z głównymi danymi Pokémonów, podstawowymi statystykami, typami, zdolnościami, zestawami do nauki ruchu, wielojęzycznymi nazwami gatunków i ewolucjami.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - Niemieckie nazwy, zespoły i opisy postaci („lista wszystkich zespołów”, „postacie”), różnice płci i błyszczące Pokémony.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 - Globalne listy wstążek, transakcje w grze i Trujące Pokémony dla wszystkich pokoleń (zapisane jako offline HTML).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - Szczegółowe listy prezentów i transakcji związanych z edycją od Kanto do Paldea i Z-A.
5. **Arkusz kalkulacyjny społeczności (`Legal_Matching_Pokeballs.xlsx`)**:
 - Szczegółowa tabela wszystkich możliwych do złapania Pokémonów w poszczególnych edycjach i pasująca estetyka Pokéballa.

---

## 4. Szybkie wykonanie całości (Wszystko-w-jednym Runner)

Aby uruchomić całą pipeline ze wszystkimi skryptami w poprawnej kolejności za pomocą jednego polecenia, użyj `run_pipeline.py`:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Ten runner automatycznie zajmuje się:
1. `update_data.py` (aktualizacja danych zewnętrznych i submodułów Git)
2. `build_database.py` (generowanie `assets/db/pokedex.sqlite` z danymi podstawowymi)
3. `update_pokemon_languages.py` (synchronizacja wszystkich 10 języków franczyzy dla wszystkich gatunków)
4. `update_evolutions_db.py` (wzbogacanie drzew ewolucji)
5. `update_cap_locks_and_trades.py` (wdrażanie blokad czapek, cosplay i wymian)
6. `optimize_databases.py` (tworzenie indeksów pokrywających, `ANALYZE`, `VACUUM`)

---

## 5. Przebieg ręczny (pojedyncze kroki)

Jeśli poszczególne skrypty mają być uruchamiane ręcznie:

### Krok 1: Aktualizacja zewnętrznych danych surowych i podmodułów
```bash
python update_data.py
```
*Pobiera aktualne pamięci podręczne HTML, pobiera najnowszy plik `Legal_Matching_Pokeballs.xlsx` i aktualizuje podmoduł `api-data` do najnowszej wersji.*

### Krok 2: Zbuduj główną bazę danych SQLite
```bash
python tool/data_pipeline/build_database.py
```
*Tworzy `assets/db/pokedex.sqlite`, wczytuje wszystkie 1.025+ Pokémonów i 250+ form oraz agreguje ponad 500 blokad Shiny.*

### Krok 3: Synchronizacja wielojęzycznych nazw Pokémon
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Dynamicznie odczytuje wszystkie języki z serii z `lib/i18n/languages.json`, dodaje brakujące kolumny (`name_fr`, `name_ja`, itd.) za pomocą `ALTER TABLE` i wypełnia nazwy na podstawie offline'owych plików JSON PokeAPI.*

### Krok 4: Wzbogacanie drzew rozwojowych
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Oblicza drzewa rozwojowe, rozgałęzienia i wyzwalacze.*

### Krok 5: Wprowadzanie kapeluszy, cosplayów i wymian
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Wprowadza Kapturki Pikachu, formy cosplayów i wymiany do `assets/db/pokedex.sqlite` i `database/pokedex.sqlite`.*

### Krok 6: Tworzenie indeksów, optymalizacja i VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Tworzy indeksy pokrywające, wykonuje `ANALYZE`, `PRAGMA optimize;` i `VACUUM`.*

---

## 6. Przegląd tabel w `pokedex.sqlite`

| Tabela | Opis | Ważne wskaźniki |
|---|---|---|
| `pokemony` | Podstawowe dane dla wszystkich ponad 1025 Pokémonów, w tym 10 kolumn w języku franczyzowym (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `KLUCZ PODSTAWOWY (id)` |
| „formy” | Formy alternatywne, Mega, G-Max, Regionalne | `idx_forms_poke (pokemon_id)` |
| `zamówienia_dex` | Regionalne zamówienia Pokédexu | `idx_dex_orders_poke_dex (pokemon_id, nazwa_dexu, indeks_zamówienia)` |
| `specjalne_deksy` | Specjalne Deksy (np. Legendarne, Ultra Bestie) | `idx_special_dexes_poke_dex (idx_special_dexes_poke_dex (idx_pokemon, nazwa_dex)` |
| `pokemon_ruchy` | Zestawy do nauki ataku wszystkich wersji | `idx_pokemon_moves_poke (pokemon_id, grupa_wersji)` |
| `umiejętności_pokemonów` | Umiejętności i ukryte zdolności | `idx_pokemon_abilities_poke (pokemon_id)` |
| „spotkania” | Lokacje i rodzaje spotkań | `idx_encounters_poke (pokemon_id, grupa_wersji)` |
| „ewolucja” | Kompletne drzewa rozwojowe | `KLUCZ PODSTAWOWY (id_gatunku)` |
| „wstążki” | Wstążki wszystkich pokoleń | `KLUCZ PODSTAWOWY (id)` |
| `znaki` | Postacie wszystkich wydań | `KLUCZ PODSTAWOWY (id)` |
| `błyszczące_loki` | Wszystkie błyszczące zamki (wersja globalna i edycja) | `KLUCZ PODSTAWOWY (id_pokemona, nazwa_formy, wersja_gry)` |
| `kulki_legalne` | Legalne Poké Balle dla Pokémonów i edycji | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Weryfikacja i zapewnienie jakości

Po każdym wykonaniu potoku należy upewnić się, że wygenerowana baza danych jest kompletna i wolna od błędów:

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

## 8. Konwencje ścieżki i rozwoju

Wszystkie skrypty w tym katalogu korzystają z dynamicznego, względnego rozwiązywania ścieżek:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Nigdy nie kodować na sztywno absolutnych ścieżek systemu operacyjnego.
- Nie umieszczać tymczasowych plików JSON w `assets/data/`; wszystkie dane statyczne powinny trafiać bezpośrednio do relacyjnej bazy danych SQLite `assets/db/pokedex.sqlite`.
