# 🔴 PokéVault

> **Sprachen:** 🇬🇧 [English](README.md) | 🇩🇪 [Deutsch](README.de.md)

**PokéVault** ist ein umfassender, vollständig anpassbarer Begleiter für Pokémon-Trainer, Sammler und Shiny-Hunter, entwickelt mit Flutter. Egal, ob du einen regionalen Dex, einen nationalen Dex, einen Form-Dex oder einen Shiny-Dex planst – PokéVault hilft dir dabei, deinen Fortschritt ganz einfach im Blick zu behalten und liefert dir die nötigen Werkzeuge für deine Shiny-Jagd.

![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![Lizenz](https://img.shields.io/badge/Lizenz-GPL--3.0-blue.svg)

## ✨ Hauptfunktionen

* **Multi-Dex Verwaltung:** Erstelle beliebig viele Tracker für verschiedene Spiele oder Generationen.
* **Detailliertes Form-Tracking:** Volle Unterstützung für Regionalformen, Mega-Entwicklungen, Gigadynamax und Spezialformen (Pokusan, Vivillon, Icognito etc.).
* **PC-Box & Listen-Ansicht:** Betrachte deine Pokémon im klassischen "PC-Box"-Raster oder in einer detaillierten Liste.
* **Shiny Tracking:** Tracke normale und schillernde (Shiny) Pokémon komplett separat.
* **Passende Pokébälle (Matching Balls):** Erhalte aus der Community kuratierte Empfehlungen für die besten Pokébälle (für die normale *und* die Shiny-Variante)!
* **📊 Fortschrittlicher Fangraten-Rechner:** Präzise Berechnung der Fangwahrscheinlichkeit über alle Generationen hinweg, inkl. spezieller Mechaniken aus *Pokémon Legenden: Arceus* und *Pokémon Legenden: Z-A*.
* **🧬 Shiny-Zucht & Routen-Rechner:** Berechnet mehrstufige Zuchtketten (inkl. Ditto und Baby-Pokémon) und zeigt exakte Wahrscheinlichkeiten für die Ziel-Nachkommen an.
* **📖 Ausführliche Shiny-Hunting-Guides:** Schritt-für-Schritt-Anleitungen für generationsspezifische Methoden (z. B. PokéRadar, DexNav, Sandwich-Rezepte).
* **☁️ Cloud Sync & Offline-First:** 100% Offline-fähig mit lokaler SQLite-Datenbank. Optionale Synchronisierung über dein privates Google Drive.
* **Volle Personalisierung:** Unterstützt Dark/Light Mode sowie individuell anpassbare Akzent- und Hintergrundfarben.
* **Mehrsprachig:** Verfügbar auf Deutsch und Englisch.

## 📸 Screenshots

| Home Screen | PC Box Ansicht |
| :---: | :---: |
| <img src="assets/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="assets/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="assets/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Pokémon Details & Matching Balls** | **Dex Erstellung & Filters** |
| <img src="assets/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="assets/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="assets/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

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

4. Externe Daten herunterladen:
Lade die aktuellsten Daten-Repositories und WIkis herunter, die für die Datenbank benötigt werden:
   ```bash
   python3 update_data.py
   ```

5. SQLite Datenbank generieren:
   *PokéVault benötigt eine vorkompilierte SQLite-Datenbank für die Pokémon-Basisdaten.* 
   Stelle sicher, dass du das Skript ausführst, um `assets/db/pokedex.sqlite` zu generieren:
   ```bash
   python3 bin/build_database.py
   ```

6. App starten:
   ```bash
   flutter run
   ```

## 🛠️ App kompilieren (Build)

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

**Web:**
```bash
flutter build web --release
```

## 🤝 Daten ergänzen (Community Contributions)
Fehlen dir Fundorte oder passen die Matching Balls nicht? Du kannst diese Daten in den JSON-Dateien im Verzeichnis `bin/` ergänzen (falls vorhanden) oder direkt über Issues/Pull Requests beitragen.

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
Dieses Projekt ist lizenziert unter der [GNU General Public License v3.0 (GPL-3.0)](LICENSE).

**Haftungsausschluss:** Pokémon und alle zugehörigen Namen sind Marken und © von Nintendo, Creatures Inc., und GAME FREAK inc. Dies ist ein kostenloses, nicht-kommerzielles Fan-Projekt und steht in keinerlei Verbindung zu Nintendo und wird von diesen weder unterstützt noch gesponsert.


