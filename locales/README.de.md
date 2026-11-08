# 🔴 PokéVault

> **Languages / Sprachen:** **[🇩🇪 Deutsch](README.de.md)** | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** ist ein umfassender, vollständig anpassbarer Begleiter für Pokémon-Trainer, Sammler und Shiny-Hunter, entwickelt mit Flutter. Egal, ob du einen regionalen Dex, einen nationalen Dex, einen Form-Dex oder einen Shiny-Dex planst – PokéVault hilft dir dabei, deinen Fortschritt ganz einfach im Blick zu behalten und liefert dir die nötigen Werkzeuge für deine Shiny-Jagd.

[![CI Quality Gate](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml/badge.svg)](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![Lizenz](https://img.shields.io/badge/Lizenz-GPL--3.0-blue.svg)

## ✨ Hauptfunktionen

* **Multi-Dex Verwaltung:** Erstelle beliebig viele Tracker für verschiedene Spiele, Generationen oder eigene Challenges.
* **Detailliertes Form-Tracking:** Volle Unterstützung für Regionalformen, Mega-Entwicklungen, Gigadynamax und Spezialformen (Pokusan, Vivillon, Icognito etc.).
* **PC-Box & Listen-Ansicht:** Betrachte deine Pokémon im klassischen 30-Slot "PC-Box"-Raster oder in einer durchsuchbaren Liste mit nahtlosem Drag & Drop.
* **Shiny Tracking & Hunt Counter:** Tracke normale und schillernde (Shiny) Pokémon separat. Integrierter Shiny-Hunt-Zähler mit Echtzeit-Wahrscheinlichkeitsberechnung, Methodenauswahl, Phasen-Historie und Session-Timer mit AFK-Pausenerkennung.
* **🎖️ Dex Completion Cards:** Gestalte, personalisiere und exportiere hochauflösende Erfolgs-Zertifikate, Statistikkarten und Pokémon-Mosaike zum Teilen deines Fortschritts.
* **Passende Pokébälle (Matching Balls):** Erhalte aus der Community kuratierte Empfehlungen für die besten Pokébälle (für die normale *und* die Shiny-Variante)!
* **📊 Fortschrittlicher Fangraten-Rechner:** Präzise Berechnung der Fangwahrscheinlichkeit über alle Generationen hinweg, inkl. spezieller Mechaniken aus *Pokémon Legenden: Arceus* und *Pokémon Legenden: Z-A*.
* **🧬 Shiny-Zucht & Routen-Rechner:** Berechnet mehrstufige Zuchtketten (inkl. Ditto und Baby-Pokémon) und zeigt exakte Wahrscheinlichkeiten für die Ziel-Nachkommen an.
* **📖 Ausführliche Shiny-Hunting-Guides:** Schritt-für-Schritt-Anleitungen für generationsspezifische Methoden (z. B. PokéRadar, DexNav, Sandwich-Rezepte).
* **🎮 In-App Bedienung & Shortcuts Übersicht:** Eigener Screen in den Einstellungen mit plattform-adaptiven Shortcuts, Mausbefehlen und Touch-Gesten.
* **☁️ Cloud Sync & Offline-First:** 100% Offline-fähig mit robuster lokaler SQLite-Datenbank. Optionale Synchronisierung über dein privates Google Drive mit Patch-Merge-Resilienz.
* **Volle Personalisierung:** Unterstützt Dark/Light Mode sowie individuell anpassbare Akzent- und Hintergrundfarben.
* **Mehrsprachig:** Vollständig in 13 Sprachen verfügbar (UI via Slang). Zudem unabhängige Auswahl der Pokémon-Franchise-Sprache (z. B. deutsches UI mit englischen oder japanischen Pokémon-Namen) basierend auf 10 offiziellen Franchise-Sprachen in `pokedex.sqlite`.

## 📸 Screenshots

| Home Screen | PC Box Ansicht |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Pokémon Details & Matching Balls** | **Dex Erstellung & Filters** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Erste Schritte (Lokal ausführen)

### Voraussetzungen
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (aktuelle Stable-Version empfohlen)
* Dart SDK
* Eine IDE wie VS Code oder Android Studio

### Installation
1. Repository klonen:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. In das Verzeichnis wechseln:
   ```bash
   cd pokevault
   ```

3. Abhängigkeiten herunterladen:
   ```bash
   flutter pub get
   ```

4. Externe Daten herunterladen & Submodule initialisieren:
   Lade die aktuellsten Daten-Repositories und Wikis herunter, die für die Datenbank benötigt werden:
   ```bash
   python3 update_data.py
   ```

5. SQLite-Datenbank generieren & optimieren:
   *PokéVault benötigt eine vorkompilierte SQLite-Datenbank für die Pokémon-Basisdaten.* 
   Führe das All-in-One Pipeline-Skript aus, um `assets/db/pokedex.sqlite` mit einem einzigen Befehl zu generieren und zu optimieren:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Alternativ mit `--skip-download` ausführen, falls du die externen Web-Dumps bereits besitzt und nur die Datenbank neu bauen möchtest).*

6. App starten:
   ```bash
   flutter run
   ```

## 🛠️ Build erstellen

Um einen Release-Build zu erstellen, nutze einen der folgenden Befehle:

**Android (APK):**
```bash
flutter build apk --release
```

**Windows:**
```bash
flutter build windows --release
```

**Linux:**
```bash
flutter build linux --release
```

**Linux AppImage:**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**Web:**
```bash
flutter build web --release
```

## 📚 Architektur & Dokumentation
* [Architektur-Leitfaden (`ARCHITECTURE.md`)](ARCHITECTURE.de.md): Detaillierte Übersicht über Systemarchitektur, Provider-State-Management, DAO-Persistenzmodell, Google Drive Sync Coordinator, Isolate-Translation-Bridge und Test-Quality-Gates.
* [Git-Branching & Release-Pipeline (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.de.md): Offizielles Git-Branching-Modell, Branch-Protection-Regeln, Multi-Plattform-Builds (Android APK, Windows Zip, Linux AppImage/tar.gz) und automatisierte Beta-Pre-Releases.
* [v1.7.0 Roadmap: The Language Expansion (`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md): Vollständige technische Spezifikation für getrennte Sprachen, lokalen REST-Server, Multi-Emulator-Tracking, Desktop-OCR und mobilen Kamera-Scanner.
* [Datenbank-Generierungs-Pipeline (`tool/data_pipeline/locales/README.de.md`)](../tool/data_pipeline/locales/README.de.md): Dokumentation der Offline-PokeAPI-Datenaufbereitung, Scraper, Matching-Balls-Import, Indizes und Datenbank-Kompilierung.
* [Entwickler- & Release-Werkzeuge (`tool/locales/README.de.md`)](../tool/locales/README.de.md): Automatisierte Release-Versionsverwaltung (`bump_version.py`), Test-Suites, Code-Coverage und Übersetzungspipeline (`translate_all.py`).

## 🤝 Daten ergänzen (Community Contributions)
Fehlen dir Fundorte oder passen die Matching Balls nicht? Du kannst diese Daten in den JSON-Dateien im Verzeichnis `tool/data_pipeline/` ergänzen (falls vorhanden) oder direkt über Issues/Pull Requests beitragen.

Wenn du Code, Features oder Fehlerbehebungen beisteuern möchtest, nutze bitte die entsprechenden Issue-Templates im Ordner `.github/ISSUE_TEMPLATE` und öffne einen Pull Request auf einem eigenen Feature-Branch.

## 🙏 Danksagungen & Quellen
Diese App wäre ohne diese großartigen Ressourcen aus der Community nicht möglich gewesen:
*   [PokeAPI](https://pokeapi.co/): Basisdaten und offizielle Artworks.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): Community Google Sheets als Tracker-Basis.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): Community-kuratierte Excel-Tabelle für die perfekten Pokébälle.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): Catch Rate Mechaniken.
*   [Google Gemini](https://gemini.google.com): KI-Assistenz beim Programmieren & Refactoring.
* Und viele weitere!

## 📄 Lizenz
Dieses Projekt ist lizenziert unter der [GNU General Public License v3.0 (GPL-3.0)](../LICENSE).

**Haftungsausschluss:** Pokémon und alle zugehörigen Namen sind Marken und © von Nintendo, Creatures Inc., und GAME FREAK inc. Dies ist ein kostenloses, nicht-kommerzielles Fan-Projekt und steht in keinerlei Verbindung zu Nintendo und wird von diesen weder unterstützt noch gesponsert.
