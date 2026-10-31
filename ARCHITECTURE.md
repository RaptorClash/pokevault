# PokéVault Architecture & System Documentation

Dieses Dokument beschreibt die technische Architektur, Datenhaltung, Cloud-Synchronisation, Modularisierung und Code-Standards von **PokéVault**. Es dient Entwicklern und KI-Assistenten als Referenz für Designentscheidungen und Erweiterungen.

---

## 1. Übersicht & Technologie-Stack

PokéVault ist ein plattformübergreifender Begleiter für Pokémon-Sammler (Living Dex, Formen, Shinies, Bänder & Zeichen, Shiny Hunting).

- **Framework**: [Flutter 3.x](https://flutter.dev/) (Dart SDK `^3.12`)
- **Zielplattformen**: Windows (Desktop), Android, iOS, macOS, Linux, Web
- **Zustandsverwaltung**: [Provider](https://pub.dev/packages/provider) (`DexProvider`, `SettingsProvider`, `ShinyHuntProvider`, `TutorialProvider`, `ThemeProvider`) mit strikter State-Kapselung (`UnmodifiableListView`)
- **Lokalisierung (i18n)**: [slang](https://pub.dev/packages/slang) für typsichere UI-Lokalisierung sowie `IsolateTranslator` als schlanke Bridge für Hintergrund-Isolate (`compute()`)
- **Persistenz & DAO-Schicht**:
  - SQLite via `sqflite` (Android/iOS) und `sqflite_common_ffi` (Desktop) bzw. `sqflite_common_ffi_web` (Web)
  - Modularisiert in fokussierte Data Access Objects: `PokemonDao`, `UserDexDao`, `ShinyHuntDao`, `CloudSyncDao` und `DatabaseMigrator`
  - `shared_preferences` für App-Einstellungen und Onboarding-Zustände
- **Cloud-Synchronisation**: Google Drive REST API v3 (AppData Folder) via `googleapis` & `googleapis_auth`, koordiniert über den dedizierten `GoogleDriveSyncCoordinator`

---

## 2. Gesamtarchitektur

Das folgende Diagramm visualisiert die geschichtete Architektur von PokéVault, die Trennung von UI-Komponenten über Delegaten, die Entkopplung rechenintensiver Isolate-Tasks und die modulare DAO-Datenbankschicht:

```mermaid
flowchart TD
    subgraph UI["Präsentationsschicht (UI & Widgets)"]
        HomeScreen["HomeScreen & HomeDexTreeView"]
        DexScreen["DexScreen & DexAppBarActions"]
        DexBoxView["DexBoxView (Header, Grid, SlotItem)"]
        ShinyHuntScreen["ShinyHuntCounterScreen & Widgets"]
        DexCard["DexCompletionCard & Dialog-Sektionen"]
    end

    subgraph Delegates["Delegations- & Aktionsschicht"]
        BoxActionDelegate["BoxActionDelegate & DefaultBoxActionDelegate"]
    end

    subgraph State["Zustandsverwaltung (Provider & Koordination)"]
        DexProvider["DexProvider (UnmodifiableListView State)"]
        SyncCoordinator["GoogleDriveSyncCoordinator (Debounce & Hooks)"]
        ShinyHuntProvider["ShinyHuntProvider (In-Memory Buffer)"]
        SettingsProvider["SettingsProvider & ThemeProvider"]
    end

    subgraph Computation["Rechenlogik & Isolate-Bridge"]
        DexBoxPacker["DexBoxPacker (compute Isolate-Task)"]
        DexEntryBuilder["DexEntryBuilder (compute Isolate-Task)"]
        BoxSeqCalc["BoxSequenceCalculator (Multi-Drag & Shifts)"]
        IsolateTranslator["IsolateTranslator (UI-freie i18n Bridge)"]
    end

    subgraph DAOs["Data Access Layer (DAOs & Migrator)"]
        DatabaseService["DatabaseService (Zentrale Fassade)"]
        PokemonDao["PokemonDao (Read-Only pokedex.sqlite)"]
        UserDexDao["UserDexDao (CRUD user_data.sqlite)"]
        ShinyHuntDao["ShinyHuntDao (CRUD shiny_hunts)"]
        CloudSyncDao["CloudSyncDao (Export & PRAGMA Patch-Merge)"]
        DatabaseMigrator["DatabaseMigrator (Schema v1-v29+, Indexes)"]
    end

    subgraph Storage["Persistenz & Dateisystem"]
        PathHelper["DatabasePathHelper (Portable Pfade & Test-Isolierung)"]
        PokedexDB[("pokedex.sqlite (Referenzdaten)")]
        UserDataDB[("user_data.sqlite (Nutzerdaten)")]
        GoogleDrive[("Google Drive AppData (pokevault_sync.json)")]
    end

    DexScreen --> BoxActionDelegate
    BoxActionDelegate --> DexBoxView
    DexBoxView --> DexProvider
    HomeScreen --> DexProvider
    ShinyHuntScreen --> ShinyHuntProvider
    DexCard --> DexProvider

    DexProvider --> SyncCoordinator
    DexProvider --> DexBoxPacker
    DexProvider --> DexEntryBuilder
    DexBoxPacker --> IsolateTranslator
    DexEntryBuilder --> IsolateTranslator

    DexProvider --> DatabaseService
    ShinyHuntProvider --> DatabaseService
    SyncCoordinator --> GoogleDrive
    SyncCoordinator --> CloudSyncDao

    DatabaseService --> PokemonDao
    DatabaseService --> UserDexDao
    DatabaseService --> ShinyHuntDao
    DatabaseService --> CloudSyncDao
    DatabaseService --> DatabaseMigrator

    DatabaseService --> PathHelper
    PokemonDao --> PokedexDB
    UserDexDao --> UserDataDB
    ShinyHuntDao --> UserDataDB
    CloudSyncDao --> UserDataDB
```

---

## 3. Datenbank-Architektur & DAO-Modell (Dual-SQLite)

PokéVault trennt strikt zwischen unveränderlichen statischen Franchise-Daten und dynamischen Nutzerdaten:

```
┌─────────────────────────────────────────┐       ┌─────────────────────────────────────────┐
│             pokedex.sqlite              │       │            user_data.sqlite             │
│   (Read-Only Referenzdaten / PokemonDao)│       │  (Read-Write Nutzerdaten / UserDexDao)  │
├─────────────────────────────────────────┤       ├─────────────────────────────────────────┤
│ • pokemon (1025+ National Dex)          │       │ • user_dexes (Konfigurationen)          │
│ • forms (Mega, G-Max, Regional)         │       │ • folders (Ordnerhierarchie)            │
│ • encounters & dex_orders               │       │ • folder_structure (Relationen)         │
│ • pokemon_moves & abilities             │       │ • user_pokemon (Status/Shinies)         │
│ • ribbons, marks & catch_rates          │       │ • shiny_hunts (Zähler & Phasen)         │
│ • shiny_locks (502+ globale & lok. Locks│       │                                         │
└─────────────────────────────────────────┘       └─────────────────────────────────────────┘
```

### 3.1 Die Data Access Objects (DAOs)
Der frühere monolithische `DatabaseService` fungiert nun als schlanke Fassade und delegiert alle Operationen an spezialisierte DAOs:
- **`PokemonDao`**: Behandelt alle lesenden Zugriffe auf `pokedex.sqlite`. Kapselt In-Memory-Caches für Pokémon, Attacken, Bänder, Bälle, Formen und Shiny-Locks.
- **`UserDexDao`**: Verantwortlich für alle CRUD-Operationen der Nutzertabellen in `user_data.sqlite` (`user_dexes`, `folders`, `folder_structure`, `user_pokemon`), inklusive verwaister Datensätze (Orphan-Cleanup).
- **`ShinyHuntDao`**: Verwaltet aktive und archivierte Shiny-Hunts, Jagd-Phasen und inkrementelle Zählerstände.
- **`CloudSyncDao`**: Bietet `exportCloudSyncData()` und transaktionales `mergeCloudSyncData()` mit dynamischer `PRAGMA table_info`-Spaltenprüfung für abwärts- und aufwärtskompatiblen Datenabgleich.
- **`DatabaseMigrator`**: Kapselt Schema-Migrationen (v1 bis v29+), Index-Erstellung (`ensureUserDataIndexes`, `ensureAppDatabaseIndexes`) und sichere Downgrade-Routinen.

### 3.2 Portabilität & Pfadauflösung (`DatabasePathHelper`)
Gemäß Repository-Richtlinie liegen Datenbanken portabel im Unterverzeichnis `database/`, **niemals** im Windows-Dokumente-Ordner:
- **Entwicklungsumgebung (Desktop)**: `<project_root>/database/` (erkannt via vorhandene `pubspec.yaml`).
- **Release / Portable Exe (Desktop)**: `<exe_dir>/database/` direkt neben der ausführbaren Datei.
- **Read-Only Fallback**: Falls das Verzeichnis schreibgeschützt ist (z. B. `C:\Program Files`), fällt die App automatisch auf `<application_support_dir>/database/` zurück.
- **Legacy Migration**: Existieren ältere Datenbanken im Dokumente-Ordner, migriert `DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded()` diese transparent, prüft Zeitstempel für Konfliktlösungen und legt Sicherheitskopien (`.bak_<timestamp>`) an.
- **Parallele Test-Isolierung**: Bei automatisierten Testläufen isoliert `DatabasePathHelper` Arbeitsverzeichnisse dynamisch per Prozess-ID (`pokevault_test_dbs/proc_$pid`), um Race Conditions und Lock-Kollisionen bei parallelen Test-Suites auszuschließen.

---

## 4. Zustandsverwaltung, Kapselung & Koordination

### 4.1 State-Kapselung mit `UnmodifiableListView`
In `DexProvider` sind interne Zustände (`_userDexes`, `_folders`) privat geschützt. Öffentliche Getter geben unmodifizierbare Ansichten (`UnmodifiableListView`) zurück. Mutationen erfolgen ausnahmslos über dedizierte Business-Methoden (`createUserDex`, `deleteFolder`, `updatePokemonStatus`), wodurch Seiteneffekte und unkontrollierte In-Memory-Zustandsänderungen verhindert werden.

### 4.2 `GoogleDriveSyncCoordinator`
Die Cloud-Synchronisation ist aus dem `DexProvider` in den eigenständigen `GoogleDriveSyncCoordinator` ausgelagert:
- **Debounced Upload**: Verhindert Server-Überlastung bei schnellen Nutzerinteraktionen durch einen zeitgesteuerten Debouncer.
- **Periodischer Sync**: Konfigurierbarer Intervall-Timer zum Prüfen und Herunterladen von Aktualisierungen anderer Geräte.
- **Lifecycle-Flush**: Bei App-Pausierung (`AppLifecycleState.paused` / `inactive`) werden ungespeicherte Änderungen sofort in die Cloud synchronisiert.
- **Transparente Hook-Kette**: Vor- und Nachbereitungs-Hooks (`registerBeforeUploadHook`, `registerCloudDataMergedHook`) entkoppeln State-Synchronisation von Netzwerkanfragen.

---

## 5. Rechenlogik, Entflechtung & Isolate-Sicherheit

Rechenintensive Operationen sind modularisiert und für Hintergrund-Threads (`compute()`) gehärtet:

1. **`DexBoxPacker`**:
   - Berechnet die Aufteilung von Pokémon-Listen in 30er-PC-Boxen (`generateBoxesIsolateTask`).
   - Unterstützt dynamische Box-Konfigurationen (Kanto, Johto, Living Dex, Formen).
2. **`DexEntryBuilder`**:
   - Generiert `DexDisplayEntry`-Modelle in Hintergrund-Isolates (`buildEntriesIsolateTask`).
3. **`BoxSequenceCalculator`**:
   - Mathematische Berechnungsfunktionen für Multi-Drag, Slot-Swaps, Gap-Closing und boxübergreifendes Verschieben.
4. **`IsolateTranslator` (i18n Bridge)**:
   - Hintergrund-Isolates besitzen keinen Flutter-UI-Kontext (`BuildContext`). `IsolateTranslator` stellt typsichere Übersetzungen für Regionen, Formen und Box-Titel bereit, ohne auf UI-Singletons zuzugreifen.

---

## 6. UI-Modularisierung & Interaktionsmodell

Die Benutzeroberfläche ist in handhabbare, modulare Sub-Widgets aufgeteilt:

### 6.1 `BoxActionDelegate` & `DexBoxView`
Die PC-Box-Ansicht (`DexBoxView`) ist über das `BoxActionDelegate`-Interface von der Anwendungslogik entkoppelt:
- `DexBoxHeader`: Navigation, Box-Titel und Fortschrittsanzeige.
- `DexBoxGrid`: Responsives 6x5-Raster mit automatischer Größenanpassung.
- `DexBoxSlotItem`: Einzelner Pokémon-Slot mit Sprites, Typen-Markern, Shiny-Symbolen und Drag-and-Drop-Feedback.

### 6.2 Modulare Dialoge & Screens
- **Dex Completion Cards**: Aufgeteilt in `CardAppearanceSection`, `CardTogglesSection`, `CardActionsBar` sowie Canvas-Renderer (`CardPainterRenderer`, `CardPokemonMosaic`, `CardStatsSummary`).
- **Shiny Hunt Module**: Aufgeteilt in `HuntCounterControls` (Großanzeige, Buttons), `HuntOddsCard` (Wahrscheinlichkeiten) und `HuntGameMethodSelector` (Edition & Methode).
- **Home Screen**: Navigation getrennt von `HomeDexTreeView` mit Drag-and-Drop-Sortierung.

---

## 7. Offline-Datenbank-Pipeline (`tool/data_pipeline/`)

Die Referenzdatenbank `assets/db/pokedex.sqlite` wird über eine Python-Monorepo-Pipeline generiert:
1. `python update_data.py`: Lädt aktuelle Web-Dumps (Bulbapedia, Bisafans, PokéWiki), die Legal Matching Pokéballs Tabelle und aktualisiert das PokeAPI Submodul.
2. `python tool/data_pipeline/build_database.py`: Aggregiert alle Quellen und baut die SQLite-Datenbank.
3. `python tool/data_pipeline/update_evolutions_db.py`: Ergänzt strukturierte Evolutionsbäume aus den PokeAPI-Rohdaten.
4. `python tool/data_pipeline/update_cap_locks_and_trades.py`: Integriert Shiny-Locks für Kappen-Pikachu, Cosplay-Formen und Tausche.
5. `python tool/data_pipeline/optimize_databases.py`: Erstellt Covering-Indexes, führt `ANALYZE` und `VACUUM` aus.

Ausführliche Entwickler-Anleitungen befinden sich in [tool/data_pipeline/README.md](tool/data_pipeline/README.md).

---

## 8. Qualitätssicherung & Zero-Tolerance Quality Gate

PokéVault erzwingt höchste Qualitätsstandards durch striktes Test-Driven Development (TDD) und automatisierte Prüfungen:

- **Automatisierte Tests**: Über **1.340 Tests** (`flutter test`) mit **100% Pass-Rate** über Unit-, Widget-, Integrations-, Boundary- und Adversarial-Challenger-Suiten.
- **Statische Analyse**: `flutter analyze` mit **0 Fehlern, 0 Warnungen und 0 Lints**.
- **Cross-Platform Resilience**: Stresstests für extreme Bildschirmgrößen (z. B. 320x480 bis 4K), Gestenabbruch und Sprachwechsel zur Laufzeit.
- **GitHub Actions CI**: Vollautomatisierte CI-Pipeline bei jedem Commit und Pull Request (`.github/workflows/ci.yml`).
