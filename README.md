# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](locales/README.de.md) | **[🇬🇧 English](README.md)** | [🇫🇷 Français](locales/README.fr.md) | [🇪🇸 Español](locales/README.es.md) | [🇮🇹 Italiano](locales/README.it.md) | [🇯🇵 日本語](locales/README.ja.md) | [🇰🇷 한국어](locales/README.ko.md) | [🇨🇳 简体中文](locales/README.zh-hans.md) | [🇹🇼 繁體中文](locales/README.zh-hant.md) | [🇵🇹 Português](locales/README.pt.md) | [🇳🇱 Nederlands](locales/README.nl.md) | [🇵🇱 Polski](locales/README.pl.md) | [🇷🇺 Русский](locales/README.ru.md)

**PokéVault** is a comprehensive, fully customizable companion app for Pokémon Trainers, Completionists, and Shiny Hunters, built with Flutter. Whether you are aiming for a Regional Dex, a National Dex, a Form Dex, or a Shiny Dex – PokéVault helps you keep track of your progress with ease and provides the ultimate toolset for your shiny hunts.

[![CI Quality Gate](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml/badge.svg)](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)

## ✨ Features

* **Multiple Dex Management:** Create as many trackers as you need for different games, generations, or custom challenges.
* **Deep Form Tracking:** Full support for Regional forms, Mega Evolutions, Gigantamax, and special forms (Alcremie, Vivillon, Unown, etc.).
* **PC Box & List Views:** View your Pokémon in a classic 30-slot "PC Box" grid or a detailed, searchable list view with seamless drag & drop.
* **Shiny Tracking & Hunt Counter:** Track regular and Shiny Pokémon separately. Integrated Shiny Hunt counter with real-time odds calculation, method presets, phase logging, and timer with AFK pause detection.
* **🎖️ Dex Completion Cards:** Design, customize, and export high-resolution completion cards and artwork mosaics to celebrate and share your Dex achievements.
* **Legal Matching Balls:** Get community-curated recommendations for the best Poké Balls (Matching Balls) for both normal and shiny variations!
* **📊 Advanced Catch Rate Calculator:** Accurate capture rate calculations spanning every generation, including special mechanics for *Pokémon Legends: Arceus* and *Pokémon Legends: Z-A*.
* **🧬 Shiny Breeding & Path Calculator:** Computes multi-step breeding chains (including Ditto and Baby Pokémon) and displays accurate probability odds.
* **📖 Extensive Shiny Hunting Guides:** Step-by-step instructions for generation-specific methods (e.g., Poké Radar, DexNav, Sandwich Recipes).
* **🎮 In-App Shortcuts & Gestures Guide:** Dedicated guide in Settings displaying platform-adaptive keyboard shortcuts, mouse controls, and touch gestures.
* **☁️ Cloud Sync & Offline-First:** 100% Offline Capable with a robust local SQLite database. Optional seamless backup and restore via your personal Google Drive with field-level patch-merge resilience.
* **Full Customization:** Supports Dark/Light mode and custom accent & background colors.
* **Multilingual:** Fully available in 13 languages (UI via Slang). Features independent Pokémon franchise language selection (e.g. German UI with English or Japanese Pokémon names) across 10 official franchise languages in `pokedex.sqlite`.

## 📸 Screenshots

| Home Screen | PC Box View |
| :---: | :---: |
| <img src="docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Pokémon Details & Matching Balls** | **Dex Creation & Filters** |
| <img src="docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version recommended)
* Dart SDK
* An IDE such as VS Code or Android Studio

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Navigate to the project directory:
   ```bash
   cd pokevault
   ```

3. Get the dependencies:
   ```bash
   flutter pub get
   ```

4. Download external data & initialize submodules:
   Fetch the latest data repositories and wikis used by the database generator:
   ```bash
   python3 update_data.py
   ```

5. Setup SQLite Database:
   *PokéVault relies on a pre-built SQLite database for core Pokémon reference data.* 
   Execute the all-in-one data pipeline script to generate and optimize `assets/db/pokedex.sqlite`:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Alternatively, run with `--skip-download` if you already have the external web dumps and only want to recompile the database).*

6. Run the app:
   ```bash
   flutter run
   ```

## 🛠️ Building the App

To compile a release build for your specific platform, run one of the following commands:

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

## 📚 Architecture & Documentation
* [Architecture Guide (`ARCHITECTURE.md`)](ARCHITECTURE.md): Comprehensive system overview, state architecture (Provider), DAO persistence model, Google Drive sync coordinator, Isolate translation bridge, and quality gates.
* [Git Workflow & Release Pipeline (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](docs/GIT_WORKFLOW_AND_RELEASES.md): Official Git branching model, branch protection rules, multi-platform builds (Android APK, Windows Zip, Linux AppImage/tar.gz), and automated beta pre-releases.
* [v1.7.0 Roadmap: The Language Expansion (`docs/plans/v1_7_0_the_language_expansion.md`)](docs/plans/v1_7_0_the_language_expansion.md): Full technical specification for separate languages, local REST API, multi-emulator tracking, desktop OCR, and mobile camera scanner.
* [Database Generator Pipeline (`tool/data_pipeline/README.md`)](tool/data_pipeline/README.md): Detailed developer documentation of offline PokeAPI parsing, web scrapers, legal Pokéball data, indexes, and database compilation steps.
* [Developer & Release Tools (`tool/README.md`)](tool/README.md): Documentation for automated release version bumping (`bump_version.py`), unit tests, code coverage, and the automated translation pipeline (`translate_all.py`).

## 🤝 Contributing Data (Community Fixes)
Missing encounters or do you have better Matching Ball suggestions? You can easily add or correct these data in the JSON files located in the `tool/data_pipeline/` directory (if applicable) or contribute directly via Issues/Pull Requests.

If you want to contribute code, features, or bug fixes, please use the appropriate Issue Templates in the `.github/ISSUE_TEMPLATE` folder and open a Pull Request on a dedicated feature branch.

## 🙏 Credits & Sources
This app wouldn't be possible without these amazing community resources:
*   [PokeAPI](https://pokeapi.co/): Base data and official artworks.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): Community Google Sheets.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): Community-curated Excel sheet for matching Poké Balls.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): Catch Rate mechanics.
*   [Google Gemini](https://gemini.google.com): AI assistance in coding & refactoring.
* And many more!

## 📄 License
This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).

**Disclaimer:** Pokémon and all respective names are trademark and © of Nintendo, Creatures Inc., and GAME FREAK inc. This is a free, non-commercial fan project and is not affiliated with, endorsed, or supported by Nintendo in any way.
