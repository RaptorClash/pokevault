# PokéVault v1.7.0 Roadmap: "The Language Expansion"
**Status:** In Planung / Freigegeben für Entwicklung  
**Ziel-Release:** v1.7.0  
**Vorgänger-Release:** v1.6.1 (Stabil auf GitHub / Stores)

---

## 📌 Kontext & Leitfaden für neue Chats / KI-Agenten

> [!IMPORTANT]
> **An jeden KI-Agenten oder Entwickler, der diesen Plan in einem neuen Chat liest:**
> Dieses Dokument ist die **vollständige, verbindliche Spezifikation** für PokéVault Release v1.7.0 ("The Language Expansion").
> - Alle Architektur- und Design-Entscheidungen in diesem Dokument wurden interaktiv im Detail mit dem Repository-Owner abgestimmt und freigegeben.
> - **Entwicklungs-Protokoll beachten (`AGENTS.md`)**: Keine einzige Zeile in `lib/` schreiben, bevor die entsprechenden Unit- und Integrationstests in `test/` existieren (Strict TDD: Rot -> Grün -> Refactor).
> - Abschlusskriterien für jedes Teilmodul: `flutter test` zu 100% grün, `flutter analyze` 0 Fehler, 0 Warnungen, 0 Lints.

---

## 🎯 Zusammenfassung der 4 Haupt-Säulen

PokéVault 1.7.0 erweitert die App weit über ein reines Übersetzungs-Update hinaus zu einem vollwertigen, sprachunabhängigen Automatisierungs-Ökosystem:

1. **Multi-Language Core (Getrennte Sprachen & Automatisierungs-Skript)**:
   - **App-Sprache** (UI, Menüs, Dialoge) und **Pokémon-Sprache** (Namen, Formen, Bänder) sind vollständig unabhängig voneinander wählbar (z.B. App auf Deutsch, Pokémon-Namen auf Japanisch oder Englisch).
   - `pokedex.sqlite` wird auf alle **10 offiziellen Franchise-Sprachen** erweitert (DE, EN, FR, ES, IT, JA, KO, ZH-Hans, ZH-Hant).
   - Master-Sprache im Quellcode ist Deutsch (`strings_de.i18n.json`). Ein Python-Skript (`tool/translate_all.py`) synchronisiert vollautomatisch via `deep-translator` alle weiteren Zielsprachen, maskiert geschützte Variablen (`{count}`, `{name}`, `\n`) und kompiliert die Slang-Dateien.

2. **Threadsafe Externe Automatisierung (Lokale REST API + CLI Tool + Emulator-Lua)**:
   - Integrierter lokaler HTTP-Server (`127.0.0.1` / `0.0.0.0`, Port standardmäßig `59123`, optionaler Auth-Token) in PokéVault.
   - Erlaubt Emulatoren (BizHawk, mGBA) und externen Skripten verzögerungsfreie Kommunikation (<1ms Latenz) mit sofortiger Benutzeroberflächen-Aktualisierung.
   - Vollwertiges CLI-Tool (`bin/pokevault_cli.dart`) mit `--json`-Output und automatischem Fallback auf Headless-SQLite (WAL-Modus), wenn die grafische App geschlossen ist.
   - Mitgeliefertes, sprachunabhängiges Lua-Skript (`tool/pokevault_tracker.lua`) für Emulatoren.

3. **Multi-Emulator Support & Intelligentes Shiny Hunting**:
   - Paralleles Betreiben mehrerer Emulator-Instanzen (z. B. 4x mGBA für Starter-Resets) mit Zuweisung per `instance_id`.
   - Erkennung von Soft Resets, Zucht/Ei-Schlupf und wilden Begegnungen.
   - **Phasen-Shiny-Tracking**: Unerwünschte Shinies während eines aktiven Hunts werden als Phase im Hunt geloggt, der Haupt-Hunt bleibt aktiv, und der Dex-Eintrag erfolgt erst bei tatsächlichem Fang.

4. **Desktop Auto-Tracker (OCR) & Mobile Live-Scanner (PiP)**:
   - **Desktop**: Bildschirm- oder Einzelfenster-Capture mit mehrsprachiger OCR für Fänge, Geschlechter (♂/♀), Shinies, Alphas (Legenden: Arceus) und Entwicklungs-Tracking ("Schlauer Dex").
   - **Mobile**: Live-Kamera-Scanner (Google ML Kit) für Switch/3DS-Bildschirme mit schwebendem Mini-Viewfinder (Picture-in-Picture), sodass die App während des Scannens uneingeschränkt weiterbedient werden kann.

---

## 🏗️ Detaillierte Modul-Spezifikationen

```mermaid
flowchart TD
    subgraph Data Layer & Translation Pipeline
        DE_MASTER["Master: lib/i18n/strings_de.i18n.json"] --> PY_TRANS["tool/translate_all.py (deep-translator)"]
        PY_TRANS --> JSON_ALL["strings_en, fr, es, it, ja, ko, zh, pt, nl..."]
        JSON_ALL --> SLANG["dart run slang -> lib/i18n/strings.g.dart"]
        
        POKEAPI["PokeAPI Submodule"] --> BUILD_DB["tool/data_pipeline/build_database.py"]
        BUILD_DB --> POKEDEX_DB["assets/db/pokedex.sqlite (10 Sprachen)"]
    end

    subgraph State & Core Logic
        SETTINGS["SettingsProvider\n- currentLanguage (UI)\n- pokemonLanguage (Names)\n- serverHost / serverPort / serverAuthToken"]
        DEX_PROV["DexProvider / UserDex"]
        HUNT_PROV["ShinyHuntProvider (Multi-Instance & Phasen)"]
        POKE_DAO["PokemonDao & Pokemon Model (names Map)"]
        SETTINGS --> POKE_DAO
        DEX_PROV --> POKE_DAO
    end

    subgraph External Automation & CLI
        LOCAL_SERVER["LocalApiServer (HttpServer loopback / custom host)"]
        DEX_PROV <--> LOCAL_SERVER
        HUNT_PROV <--> LOCAL_SERVER
        
        LUA_SCRIPT["BizHawk / mGBA (tool/pokevault_tracker.lua)"] -->|POST /api/shiny/inc & /mark| LOCAL_SERVER
        CLI_TOOL["PokéVault CLI (bin/pokevault_cli.dart)"] -->|REST API (Live GUI)| LOCAL_SERVER
        CLI_TOOL -->|Fallback: Direct SQLite WAL| USER_DB["database/user_data.sqlite"]
    end

    subgraph Detection & Capture Engines
        DESKTOP_OCR["Desktop Window/Screen Capture + OCR Engine"] -->|Event: Caught / Evolved| DEX_PROV
        MOBILE_CAM["Mobile Point-and-Catch Scanner (ML Kit + Floating PiP)"] -->|Event: Caught| DEX_PROV
    end
```

---

### Säule 1: Sprach-Architektur & Übersetzungs-Pipeline

#### 1.1 Datenbank (`pokedex.sqlite`)
In `tool/data_pipeline/build_database.py` wird die Tabelle `pokemon` erweitert:
```sql
CREATE TABLE IF NOT EXISTS pokemon (
    id INTEGER PRIMARY KEY, 
    name_de TEXT, name_en TEXT, name_fr TEXT, name_es TEXT, name_it TEXT,
    name_ja TEXT, name_ko TEXT, name_zh_hans TEXT, name_zh_hant TEXT,
    has_gender_differences INTEGER, gender_rate INTEGER, capture_rate INTEGER,
    evolution_chain_id INTEGER, egg_groups TEXT, weight REAL, speed INTEGER,
    catch_rate_tags TEXT
);
```
Die Namen liegen im lokalen Submodul `tool/data_pipeline/api-data/data/api/v2/pokemon-species/{id}/index.json` unter `"names"` für alle 10 Sprach-Codes bereits offline vor.

#### 1.2 Dart-Modell `Pokemon` (`lib/models/pokemon.dart`)
- Hält ein `final Map<String, String> names;`.
- `getName(String languageCode)`:
  1. Sucht exakten Code (z.B. `'fr'`).
  2. Fallback für Chinesisch (`'zh-Hans'` $\rightarrow$ `'zh-hans'`).
  3. Fallback auf `'en'`, dann `'de'`, sonst `'Unknown'`.

#### 1.3 `SettingsProvider` (`lib/providers/settings_provider.dart`)
- `currentLanguage`: Aktive App-Sprache (gespeichert in `prefs.getString('language')`).
- `pokemonLanguage`: Pokémon-Sprache (gespeichert in `prefs.getString('pokemonLanguage') ?? 'auto'`).
- `effectivePokemonLanguage`: Liefert `pokemonLanguage`, wenn nicht `'auto'`; falls `'auto'`, prüft ob `currentLanguage` eine der 10 Franchise-Sprachen ist (sonst Fallback auf `'en'`).

#### 1.4 Übersetzungsskript `tool/translate_all.py`
- Benötigt: `pip install deep-translator`.
- Liest `lib/i18n/strings_de.i18n.json`.
- Schützt Platzhalter per Regex: `{count}`, `{name}`, `\n`, Markdown-Links, Tags.
- Übersetzt fehlende oder veränderte Keys in alle Zielsprachen: `en`, `fr`, `es`, `it`, `ja`, `ko`, `zh-Hans`, `zh-Hant`, `pt`, `nl`, `pl`, `ru`.
- Führt abschließend `dart run slang` aus.

---

### Säule 2: Lokale REST API, CLI & Lua-Integration

#### 2.1 Warum Lua sprachunabhängig ist
Im Arbeitsspeicher (RAM) der Emulatoren (GBA, NDS) speichert die Pokémon-Engine die Spezies als **16-Bit Integer (1 bis 1025)**. Ein Glumanda hat immer den Wert `4`, Bisasam immer `1`, egal ob die ROM deutsch, englisch oder japanisch ist!
Einzig die RAM-Adresse der Party / Wild-Struktur variiert nach Spieledition und Region. Das Lua-Skript ermittelt dies über den 4-stelligen Game-Code im ROM-Header:
- `BPRD`: Pokémon Feuerrot (Deutsch) $\rightarrow$ Party-Offset `0x02024284`
- `BPRE`: Pokémon FireRed (USA) $\rightarrow$ Party-Offset `0x02024284`
- `BPEE`: Pokémon Emerald (USA) $\rightarrow$ Party-Offset `0x020244EC`
- `BPED`: Pokémon Smaragd (Deutsch) $\rightarrow$ Party-Offset `0x020244EC`

#### 2.2 Server-Endpunkte (`lib/services/api/local_api_server.dart`)
Server läuft standardmäßig auf `http://127.0.0.1:59123` (konfigurierbar in Settings):
- `GET /api/status`: Liefert Server-Status, aktiven Dex, Hunt-Zähler und aktive Instanzen.
- `GET /api/dex/list`: Liste aller Dexe mit IDs, Fangstatistiken und Regionen.
- `POST /api/dex/mark`:
  ```json
  {
    "dexId": "dex_kanto",
    "pokemonId": 25,
    "gender": "female",
    "form": "normal",
    "shiny": true,
    "caught": true
  }
  ```
- `POST /api/shiny/inc`:
  ```json
  {
    "huntId": "optional_hunt_id",
    "instanceId": "emu_1",
    "step": 1
  }
  ```
- `POST /api/shiny/phase`:
  ```json
  {
    "huntId": "hunt_mewtwo",
    "caughtPokemonId": 41,
    "caughtPokemonName": "Zubat",
    "encounters": 340,
    "caught": false
  }
  ```
- `POST /api/sync`: Stößt Google-Drive-Sync an.

#### 2.3 CLI Tool (`bin/pokevault_cli.dart`)
Syntax:
```bash
pokevault dex list [--json]
pokevault dex create --name "Neuer Dex" --region kanto [--shiny]
pokevault mark --dex <id> --pokemon <id|name> [--caught] [--shiny] [--gender m|f] [--form <form>]
pokevault shiny list [--json]
pokevault shiny inc [--id <hunt_id>] [--instance <emu_id>] [--step 1]
pokevault shiny phase --id <hunt_id> --pokemon <name> --encounters <num> [--caught]
pokevault sync
pokevault export --format json|csv|xlsx --out export.json
```
**Dual-Modus:** Prüft zuerst, ob `http://127.0.0.1:59123` erreichbar ist. Wenn ja, wird der Befehl per REST weitergeleitet (GUI aktualisiert sich live). Wenn nein, agiert die CLI headless direkt mit SQLite WAL-Locking auf `user_data.sqlite`.

---

### Säule 3: Multi-Emulator Tracking & Erweitertes Shiny-Hunting

1. **Multi-Instanz Encounter Aggregation**:
   - Beim Multi-Hunting (z. B. 4x Starter-Resets auf 4 mGBA Fenstern):
   - Jede Instanz sendet `POST /api/shiny/inc` mit ihrer `instanceId` (`emu_1` ... `emu_4`).
   - Standardmodus: Alle Instanzen erhöhen den Encounter-Zähler des aktiven Hunts (4-fache Zählgeschwindigkeit).
   - Zuweisungsmodus: Instanz `emu_1` und `emu_2` sind Hunt A zugeordnet, `emu_3` und `emu_4` Hunt B.
2. **Methoden-Tracking**:
   - Soft Reset (Erkennt Reboot des Titelschirms / RAM-Reset).
   - Zucht / Masuda (Erkennt Ei-Schlupf-Event).
   - Wilde Begegnungen / SOS-Chaining.
3. **Phasen-Shinys**:
   - Wenn ein Shiny auftaucht, das nicht das Ziel-Pokémon ist (z. B. Zubat bei Mewtu-Hunt):
   - Wird als Phase in `hunt.phaseHistory` (`ShinyPhaseEntry`) dokumentiert.
   - Der aktuelle Encounter-Zähler der Phase wird festgehalten und der Zähler für die nächste Phase zurückgesetzt.
   - **Wichtig**: Das Phasen-Shiny wird im Pokédex erst eingetragen, wenn der Spieler es auch wirklich fängt (`caught: true`).

---

### Säule 4: Desktop OCR-Overlay & Mobile PiP-Scanner

1. **Desktop OCR Engine (`lib/services/tracker/ocr_detection_engine.dart`)**:
   - Scannt Vollbild oder wählbares Fenster (z.B. mGBA, DeSmuME, Ryujinx).
   - Regex-Fangmuster für DE, EN, FR, ES, IT, JA:
     - DE: `"([^"]+) wurde gefangen!"`
     - EN: `"Gotcha! ([^"]+) was caught!"`
     - FR: `"([^"]+) est capturé!"`
     - ES: `"¡([^"]+) atrapado!"`
     - IT: `"Hai catturato ([^"]+)!"`
     - JA: `"([^"]+)を つかまえた!"`
   - Geschlecht: `♂` / `♀`.
   - Alpha-Pokémon: Elite-Keyword / Rote-Augen-Symbolik.
   - **Schlauer Entwicklungs-Tracker**: Erkennt `"<Basis> entwickelt sich zu <Entwicklung>!"`. Markiert die Entwicklung im Dex und entfernt bei aktivem Living-Dex-Modus auf Wunsch automatisch die Vorentwicklung.
2. **Mobile Live-Scanner mit PiP (`lib/screens/scanner/mobile_scanner_screen.dart`)**:
   - Nutzt Kamera + Google ML Kit Text Recognition für die Nintendo Switch Textbox.
   - Kann als schwebendes Mini-Fenster (Picture-in-Picture) oder Bottom Drawer minimiert werden.
   - Die App bleibt im Hintergrund 100% bedienbar.
   - Akustisches und haptisches Feedback beim Fangen.

---

### Säule 5: Rotom-Tutorial-System (Kapitel v3) & Dokumentation

1. **Rotom-Tutorial (`lib/models/tutorial_step.dart`)**:
   - Neuer Versionsschritt `isNewInV17 => version == 3;`.
   - Kapitel:
     - `module_languages`: Sprachauswahl & Unabhängigkeit.
     - `module_tracker`: Auto-Tracker & Multi-Emulator-Betrieb.
     - `module_scanner`: Mobiler PiP-Kamera-Scanner.
     - `module_automation`: Server & CLI-Nutzung.
2. **Dokumentation**:
   - `docs/CLI_AND_API.md`: Vollständige REST API & CLI Dokumentation mit cURL-Beispielen.
   - `docs/LUA_TRACKER_GUIDE.md`: Anleitung für BizHawk & mGBA, Offsets, Hook-Logik.
   - `docs/prototypes/v1_7_0_prototype.html`: Interaktiver Prototyp für Entwickler und Tester.

---

## 🧪 Test- & Verifikations-Plan (TDD Strict)

Vor jeglicher Implementierung in `lib/` müssen folgende Tests in `test/` erstellt werden:

1. `test/services/language_expansion_test.dart`:
   - `Pokemon.getName` für alle 10 Sprachen.
   - `SettingsProvider.effectivePokemonLanguage` mit Fallback-Mechanismus.
   - Platzhalter-Maskierung und -Demaskierung des Übersetzungsskripts.
2. `test/services/local_api_server_test.dart`:
   - Starten des lokalen Servers auf dynamischem Testport.
   - Multi-Emulator Inkrementierung mit `instance_id`.
   - Phasen-Shiny Logging (Prüfung: Zähler, Phasen-History, Dex-Eintrag nur bei Catch).
   - Threadsafe Concurrency Test (20 gleichzeitige API-Anfragen).
3. `test/services/ocr_detection_engine_test.dart`:
   - Fangmeldungen in 6 Sprachen.
   - Geschlechts-, Shiny- und Alpha-Extraktion.
   - Entwicklungs-Erkennung und Vorentwicklungs-Austragung.
4. `test/cli/pokevault_cli_test.dart`:
   - Parameter-Parsing (`--json`, `--instance`, `--shiny`).
   - Headless-Ausführung gegen SQLite.
5. **Quality Gate**:
   ```bash
   flutter test
   flutter analyze
   ```
   Bedingung: 100% Pass Rate, 0 Errors, 0 Warnings, 0 Lints.
