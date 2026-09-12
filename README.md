# 🔴 PokéVault

> **Languages:** 🇬🇧 [English](README.md) | 🇩🇪 [Deutsch](README.de.md)

**PokéVault** is a comprehensive, fully customizable companion app for Pokémon Trainers, Completionists, and Shiny Hunters, built with Flutter. Whether you are aiming for a Regional Dex, a National Dex, a Form Dex, or a Shiny Dex – PokéVault helps you keep track of your progress with ease and provides the ultimate toolset for your shiny hunts.

![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)

## ✨ Features

* **Multiple Dex Management:** Create as many trackers as you need for different games or generations.
* **Deep Form Tracking:** Full support for Regional forms, Mega Evolutions, Gigantamax, and special forms (Alcremie, Vivillon, Unown, etc.).
* **PC Box & List Views:** View your Pokémon in a classic "PC Box" grid or a detailed list view.
* **Shiny Tracking:** Track regular and Shiny Pokémon completely separately.
* **Legal Matching Balls:** Get community-curated recommendations for the best Poké Balls (Matching Balls) for both normal and shiny variations!
* **📊 Advanced Catch Rate Calculator:** Accurate capture rate calculations spanning every generation, including special mechanics for *Pokémon Legends: Arceus* and *Pokémon Legends: Z-A*.
* **🧬 Shiny Breeding & Path Calculator:** Computes multi-step breeding chains (including Ditto and Baby Pokémon) and displays accurate probability odds.
* **📖 Extensive Shiny Hunting Guides:** Step-by-step instructions for generation-specific methods (e.g., Pokéradar, DexNav, Sandwich Recipes).
* **☁️ Cloud Sync & Offline-First:** 100% Offline Capable with a robust local SQLite database. Optional seamless backup and restore via your personal Google Drive.
* **Full Customization:** Supports Dark/Light mode and custom accent & background colors.
* **Multilingual:** Available in English and German.

## 📸 Screenshots

| Home Screen | PC Box View |
| :---: | :---: |
| <img src="assets/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="assets/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="assets/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Pokémon Details & Matching Balls** | **Dex Creation & Filters** |
| <img src="assets/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="assets/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="assets/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

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

4. Download external data:
Fetch the latest data repositories and wikis used by the database generator:
   ```bash
   python3 update_data.py
   ```

5. Setup SQLite Database:
   *PokéVault relies on a pre-built SQLite database for core Pokémon data.* 
   Make sure you run the database build script to generate `assets/db/pokedex.sqlite` before launching the app:
   ```bash
   python3 bin/build_database.py
   ```

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

## 🤝 Contributing Data (Community Fixes)
Missing encounters or do you have better Matching Ball suggestions? You can easily add or correct these data in the JSON files located in the `bin/` directory (if applicable) or contribute directly via Issues/Pull Requests.

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


