# 🔴 Poké Vault

> **Languages:** 🇬🇧 [English](README.md) | 🇩🇪 [Deutsch](README.de.md)

**Poké Vault** is a comprehensive, fully customizable Living Dex Tracker built with Flutter. Whether you are aiming for a Regional Dex, a National Dex, a Form Dex, or a Shiny Dex – Poké Vault helps you keep track of your progress with ease.

![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)
![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)

## ✨ Features

* **Multiple Dex Management:** Create as many trackers as you need for different games or generations (e.g., Kanto, Paldea, Isle of Armor, Indigo Disk).
* **Deep Form Tracking:** Full support for Regional forms, Mega Evolutions, Gigantamax, and special forms (Alcremie, Vivillon, Unown, etc.).
* **PC Box & List Views:** View your Pokémon in a classic "PC Box" grid or a detailed list view.
* **Shiny Tracking:** Track regular and Shiny Pokémon separately.
* **Legal Matching Balls:** Get community-curated recommendations for the best Poké Balls (Matching Balls) for both normal and shiny variations!
* **Full Customization:** Supports Dark/Light mode and custom accent & background colors.
* **Import & Export:** Easily backup and restore your progress via JSON files.
* **Multilingual:** Available in English and German.

## 📸 Screenshots

| Home Screen | PC Box View |
| :---: | :---: |
| <img src="assets/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="assets/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="assets/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Pokémon Details & Matching Balls** | **Dex Creation & Filters** |
| <img src="assets/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="assets/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="assets/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.x)
* Dart SDK

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/pokevault.git
   ```

2. Navigate to the project directory:
   ```bash
   cd pokevault
   ```

3. Get the dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## 🛠️ Data Generation (Internal)
The app uses Python and Dart scripts to generate static Dart data from external sources (e.g., PokeAPI and an Excel sheet for Matching Balls).
If you want to update the database, you can run the scripts located in the bin/ folder:
- `python bin/generate_matching_balls.py`
- `dart bin/generate_dex.dart`
- `dart bin/generate_orders.dart`

## 🤝 Help Needed: Missing Encounters (Gen 8+)
This app fetches Pokémon encounter locations from PokéAPI. However, their database is currently severely lacking data for games starting from Gen 8 (Sword/Shield DLCs, BDSP, Legends: Arceus, Scarlet/Violet).

**Want to contribute? It's super easy:**
You don't need to write any complex Dart code! All missing, incorrect, or special encounters (like gifts/events) can simply be added to a JSON file:
1. Open the file `bin/custom_encounters.json`.
2. Add the Pokémon using its National Dex ID, the generation, the game version, and its English location (just copy the structure of the existing entries).
3. **Bonus Step:** Open `lib/l10n/app_translations.dart` and add the new English location name along with its translations to the respective language maps (e.g., `_baseLocationTranslationsDe` for German). If you don't speak those languages, no worries – just skip this step!
4. Open a Pull Request with your changes.
5. I will run the generation script (`dart bin/generate_encounters.dart`) which merges your JSON data with the API data.

Any contribution to fill in these gaps is highly appreciated!

## 🏪 App Store Publishing
I currently do not own any iOS/Mac devices to compile and publish the app for Apple platforms. If anyone from the community wants to take the compiled app and publish it to the Apple App Store, Google Play Store, or any other platform, you are more than welcome to do so! 

**Conditions for publishing:**
1. The app must remain **100% free** (no ads, no in-app purchases, strictly non-commercial).
2. Proper credit must be given to this original GitHub repository in the app's store description.

## 🙏 Credits & Sources
This app wouldn't be possible without these amazing community resources:
- [PokeAPI](https://pokeapi.co/): Base data and official artworks.
- [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): Community Google Sheets.
- [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): Community-curated Excel sheet for matching Poké Balls.
- [Google Gemini](https://gemini.google.com): AI assistance in coding & refactoring.

## 📄 License
This project is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)](LICENSE). 

**Disclaimer:** Pokémon and all respective names are trademark and © of Nintendo, Creatures Inc., and GAME FREAK inc. This is a free, non-commercial fan project and is not affiliated with, endorsed, or supported by Nintendo in any way.