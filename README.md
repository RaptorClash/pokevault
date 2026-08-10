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

## 🤝 Contributing Data (Community Fixes)
Missing encounters or do you have better Matching Ball suggestions? You can easily add or correct these in the JSON files located in the `bin/` folder without any coding knowledge.

### 📍 Encounters (`bin/custom_encounters.json`)
You can add missing locations for specific games here (especially helpful for Gen 8+ since the API lacks data there).
**Format Example:**
```json
{
  "1": { 
    "gen_1": {
      "red": ["Pallet Town (Starter)"]
    }
  }
}
```

- `"1"`: The National Dex ID of the Pokémon (e.g., Bulbasaur).
- `"gen_1"`: The Generation.
- `"red"`: The English internal name of the game version.
- `"[...]"`: A list of the encounter locations in English (e.g., "Route 1", "Gift", "Trade").

### 🔴 Matching Balls (`bin/custom_matching_balls.json`)
Here you can define the perfect Poké Balls for the regular and shiny versions of a Pokémon.
Format Example:
```json
{
  "1_normal": {
    "normal": ["poke_ball", "friend_ball"],
    "shiny": ["premier_ball"]
  }
}
```
- `"1_normal"`: The Dex ID followed by an underscore and the form. Use _normal for the standard form. For regional forms, use the suffix (e.g., `"19_alola"` for Alolan Rattata or `"52_galar"` for Galarian Meowth).
- `"normal"` / `"shiny"`: The internal English names of the Poké Balls (e.g., `"great_ball"`, `"ultra_ball"`). If any ball is fine, use `["any_ball"]`.

Just open a Pull Request with your additions to the JSON files!

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