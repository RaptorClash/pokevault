# PokéVault Architecture & System Documentation

Dieses Dokument beschreibt die technische Architektur, Datenhaltung, Cloud-Synchronisation und Code-Standards von **PokéVault**. Es dient Entwicklern und KI-Assistenten als Referenz für Designentscheidungen und Erweiterungen.

---

## 1. Übersicht & Technologie-Stack

PokéVault ist ein plattformübergreifender Begleiter für Pokémon-Sammler (Living Dex, Formen, Shinies, Bänder & Zeichen, Shiny Hunting).

- **Framework**: [Flutter 3.x](https://flutter.dev/) (Dart SDK `^3.12`)
- **Zielplattformen**: Windows (Desktop), Android, iOS, macOS, Linux, Web
- **Zustandsverwaltung**: [Provider](https://pub.dev/packages/provider) (`DexProvider`, `SettingsProvider`, `ShinyHuntProvider`, `TutorialProvider`, `ThemeProvider`)
- **Lokalisierung (i18n)**: [slang](https://pub.dev/packages/slang) & `Translator` (Deutsch als Basissprache, Englisch)
- **Persistenz**:
  - SQLite via `sqflite` (Android/iOS) und `sqflite_common_ffi` (Desktop) bzw. `sqflite_common_ffi_web` (Web)
  - `shared_preferences` für App-Einstellungen und Tutorial-Zustände
- **Cloud-Synchronisation**: Google Drive REST API v3 (AppData Folder) via `googleapis` & `googleapis_auth`

---

## 2. Datenbank-Architektur (Dual-SQLite Modell)

PokéVault trennt strikt zwischen unveränderlichen statischen Franchise-Daten und dynamischen Nutzerdaten:

```
┌─────────────────────────────────┐       ┌─────────────────────────────────┐
│         pokedex.sqlite          │       │        user_data.sqlite         │
│   (Read-Only Referenzdaten)     │       │    (Read-Write Nutzerdaten)     │
├─────────────────────────────────┤       ├─────────────────────────────────┤
│ • pokemon (1025+ National Dex)  │       │ • user_dexes (Konfigurationen)  │
│ • forms (Mega, G-Max, Regional) │       │ • folders (Ordnerhierarchie)    │
│ • encounters & dex_orders       │       │ • folder_structure (Relationen) │
│ • pokemon_moves & abilities     │       │ • user_pokemon (Status/Shinies) │
│ • ribbons, marks & catch_rates  │       │ • shiny_hunts (Zähler & Phasen) │
└─────────────────────────────────┘       └─────────────────────────────────┘
```

### 2.1 Portabilität & Pfadauflösung (`DatabasePathHelper`)
Gemäß Repository-Richtlinie liegen Datenbanken portabel im Unterverzeichnis `database/`, **niemals** im Windows-Dokumente-Ordner:

- **Entwicklungsumgebung (Desktop)**: `<project_root>/database/` (erkannt via vorhandene `pubspec.yaml`).
- **Release / Portable Exe (Desktop)**: `<exe_dir>/database/` direkt neben der ausführbaren Datei.
- **Read-Only Fallback**: Falls das Verzeichnis schreibgeschützt ist (z. B. `C:\Program Files`), fällt die App automatisch auf `<application_support_dir>/database/` zurück.
- **Legacy Migration**: Existieren ältere Datenbanken im Dokumente-Ordner, migriert `DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded()` diese transparent, prüft Zeitstempel für Konfliktlösungen und legt Sicherheitskopien (`.bak_<timestamp>`) an.

### 2.2 Schema-Evolution & Downgrade-Resilienz
- **Idempotente Upgrades**: Neue Spalten werden via `_addColumnIfNotExists(db, table, column, definition)` anhand von `PRAGMA table_info` hinzugefügt.
- **Downgrade-Stabilität (`onDowngrade`)**: Bei Wechsel auf ältere App-Versionen wird die Datenbank **nicht** zerstört oder neu angelegt (`onDowngrade: downgradeUserDataTables`), sodass Versionssprünge vor und zurück verlustfrei bleiben.
- **Index-Pflicht**: Große Tabellen sind vollständig indexiert (`ensureUserDataIndexes`, `ensureAppDatabaseIndexes`), um schnelle Joins auf Moves, Abilities, Encounters und Shiny Hunts zu garantieren.

---

## 3. Zustandsverwaltung & Datenfluss

Die Kernlogik ist in vier Hauptprovider gegliedert:

1. **`DexProvider`**:
   - Verwaltet aktive `UserDex`-Instanzen, Ordnerstrukturen und gefangene Pokémon.
   - Koordiniert asynchrone Hintergrundberechnungen via `compute` in `DexLogicHelper`.
   - Registriert Lifecycle-Hooks für Cloud-Upload und -Merge (`registerBeforeUploadHook`, `registerCloudDataMergedHook`).
2. **`ShinyHuntProvider`**:
   - Führt aktive Shiny-Hunts, Zeitmessung (mit AFK-Schutz und Foreground-Erkennung) und Phasen-Historie.
   - Verwendet In-Memory-Zähler mit debounced SQLite-Flush (`_pendingDirtyHuntIds`).
3. **`SettingsProvider`**:
   - Verwaltet Themes, Akzentfarben, Sprachwechsel (`de` / `en`) und Google-Drive-OAuth-Zugangsdaten.
4. **`TutorialProvider`**:
   - Speichert gesehene Onboarding-Schritte und Feature-Flags.

---

## 4. Cloud-Synchronisation & Patch-Merge Resilienz

Die Cloud-Synchronisation speichert Backups als `pokevault_sync.json` im privaten Google Drive `appDataFolder` des Benutzers.

### 4.1 Cross-Platform OAuth2
- **Desktop & Mobile**: Startet einen lokalen HTTP-Server (`127.0.0.1:8080`), öffnet den Systembrowser und fängt den Autorisierungscode ab.
- **Web**: Nutzt die offizielle Google Sign-In Erweiterung.

### 4.2 Field-Level Patch-Merge (`GoogleDriveSyncService.mergeForUpload`)
Um zu verhindern, dass eine Desktop-App Felder überschreibt, die von einer neueren Android-Version (oder umgekehrt) eingeführt wurden:

1. Vor jedem Upload wird die bestehende Cloud-Datei heruntergeladen.
2. Der Merge vergleicht Datensätze anhand ihrer Primärschlüssel (z. B. `id` oder `dex_id + unique_id`).
3. Nur wenn der lokale Zeitstempel (`updated_at`) neuer oder gleich ist, werden lokale Felder über die Cloud-Felder gelegt (`remoteItem.addAll(localItem)`).
4. Unbekannte Spalten und Tabellen aus der Cloud bleiben vollständig erhalten.

---

## 5. Bedienung & Interaktionsmodell

PokéVault ist für Maus/Tastatur und Touchscreens gleichermaßen optimiert:

| Bereich | Desktop & Web (Maus & Tastatur) | Touch & Mobil (Gesten) |
|---|---|---|
| **Navigation** | `Backspace` / `Browser Back` | System-Zurück-Wischgeste |
| **PC-Box / Liste** | Linksklick: Toggle Status<br>Rechtsklick / `Taste I` / `Ctrl+Enter`: Info<br>Drag & Drop: Verschieben | Tippen: Toggle Status<br>Langer Druck: Info<br>Langer Druck + Ziehen: Verschieben |
| **Home Screen** | Drag & Drop am Reorder-Handle | Langer Druck für Mehrfachauswahl |
| **Shiny Counter** | `Leertaste` / `↑`: +1<br>`↓` / `-`: -1<br>`P`: Pause/Fortsetzen<br>Schloss-Symbol: Fehlklickschutz | Großes Tippfeld: +1<br>Minus-Button: -1<br>Pause-Button: Pause<br>Schloss-Symbol: Fehlklickschutz |
| **Bänder & Fähigkeiten** | Linksklick: Status<br>Rechtsklick: Details | Tippen: Status<br>Langer Druck: Details |

Die vollständige Anleitung ist in der App unter **Einstellungen → Allgemein → Bedienung & Tastaturkürzel** interaktiv einsehbar (`ControlsGuideScreen`).

---

## 6. Offline-Datenbank-Pipeline (`bin/`)

Die Referenzdatenbank `assets/db/pokedex.sqlite` wird über eine Python-Pipeline generiert:
1. `python update_data.py`: Lädt aktuelle HTML-Seiten (Bulbapedia, Bisafans, PokéWiki), die Legal Matching Pokéballs Tabelle und aktualisiert das PokeAPI Submodule.
2. `python bin/build_database.py`: Aggregiert alle Quellen und baut die SQLite-Datenbank.
3. `python bin/update_evolutions_db.py`: Ergänzt strukturierte Evolutionsbäume aus den PokeAPI-Rohdaten.

Details zur Pipeline sind in [bin/README.md](file:///c:/Marvin/Projekte/Code/pokevault/bin/README.md) dokumentiert.

---

## 7. Qualitätssicherung & CI Pipeline

- **Automatisierte Tests**: Über 840 Unit-, Widget- und Integrationstests (`flutter test`).
- **Statische Analyse**: `dart analyze --fatal-infos` mit strengen Lint-Regeln (`flutter_lints`).
- **GitHub Actions CI**: Läuft automatisch bei jedem Push und PR auf `main` / `master` (`.github/workflows/ci.yml`).
