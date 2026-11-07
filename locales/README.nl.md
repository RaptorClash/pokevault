# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | **[🇳🇱 Nederlands](README.nl.md)** | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** is een uitgebreide, volledig aanpasbare metgezel voor Pokémon-trainers, verzamelaars en Shiny-jagers, ontwikkeld met Flutter. Of je nu een regionale Dex, een nationale Dex, een Form-Dex of een Shiny-Dex plant – PokéVault helpt je om je voortgang eenvoudig bij te houden en biedt de nodige tools voor je Shiny-jacht.

[![CI Quality Gate](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml/badge.svg)](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![Lizenz](https://img.shields.io/badge/Lizenz-GPL--3.0-blue.svg)

## ✨ Hoofdfunctionaliteiten

* **Multi-Dex-beheer:** Creëer zoveel trackers als je wilt voor verschillende games, generaties of je eigen uitdagingen.
* **Gedetailleerde formuliertracking:** Volledige ondersteuning voor regionale formulieren, mega-evoluties, Gigantamax en speciale vormen (Pokusan, Vivillon, Unown, enz.).
* **PC-box en lijstweergave:** Bekijk je Pokémon in het klassieke "PC Box"-raster met 30 slots of in een doorzoekbare lijst met naadloze slepen en neerzetten.
* **Glanzende tracking- en jachtteller:** Volg normale en glanzende Pokémon afzonderlijk. Ingebouwde Shiny Hunt-teller met realtime waarschijnlijkheidsberekening, methodeselectie, fasegeschiedenis en sessietimer met AFK-pauzedetectie.
* **🎖️ Dex Completion Cards:** Ontwerp, personaliseer en exporteer prestatiecertificaten met hoge resolutie, statistische kaarten en Pokémon-mozaïeken om je voortgang te delen.
* **Bijpassende ballen:** Ontvang door de community samengestelde aanbevelingen voor de beste Poké Balls (voor de normale *en* glanzende varianten)!
* **📊 Geavanceerde calculator voor vangstpercentages:** Nauwkeurige berekening van de vangstkans voor alle generaties, inclusief speciale mechanismen uit *Pokémon Legends: Arceus* en *Pokémon Legends: Z-A*.
* **🧬 Glanzende voortplantings- en routecalculator:** Berekent voortplantingsketens in meerdere fasen (inclusief Ditto en baby Pokémon) en geeft exacte kansen voor het doelwit weer nakomelingen.
* **📖 Gedetailleerde glanzende jachtgidsen:** Stapsgewijze instructies voor generatiespecifieke methoden (bijv. PokéRadar, DexNav, sandwichrecepten).
* **🎮 In-app bediening & snelkoppelingen Overzicht:** Eigen scherm in de instellingen met platform-adaptieve snelkoppelingen, muisopdrachten en aanraakgebaren.
* **☁️ Cloud Sync & Offline-First:** 100% offline geschikt met robuuste lokale SQLite-database. Optionele synchronisatie via uw privé Google Drive met tolerantie voor het samenvoegen van patches.
* **Volledige personalisatie:** Ondersteunt de donker/licht-modus en aanpasbare accent- en achtergrondkleuren.
* **Meertalig:** Volledig beschikbaar in 13 talen (UI via Slang). Bovendien onafhankelijke selectie van de Pokémon-franchisetaal (bijvoorbeeld Duitse gebruikersinterface met Engelse of Japanse Pokémon-namen) op basis van 10 officiële franchisetalen in `pokedex.sqlite`.

## 📸 Screenshots

| Startscherm | PC Box-weergave |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Pokémon Details & Overeenkomende Ballen** | **Dex Maken & Filters** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Eerste stappen (Lokaal uitvoeren)

### Vereisten
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (aanbevolen is de actuele stabiele versie)
* Dart SDK
* Een IDE zoals VS Code of Android Studio

### Installatie
1. Repository klonen:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Naar de map wisselen:
   ```bash
   cd pokevault
   ```

3. Afhankelijkheden downloaden:
   ```bash
   flutter pub get
   ```

4. Externe gegevens downloaden & submodules initialiseren:
   Download de meest actuele gegevensrepositories en wiki's die voor de database nodig zijn:
   ```bash
   python3 update_data.py
   ```

5. SQLite-database genereren & optimaliseren:
   *PokéVault heeft een vooraf gecompileerde SQLite-database nodig voor de Pokémon-basissgegevens.* 
   Voer het alles-in-één pipeline-script uit om `assets/db/pokedex.sqlite` met één enkele opdracht te genereren en te optimaliseren:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Alternatief uitvoeren met `--skip-download` als je de externe webdumps al hebt en alleen de database opnieuw wilt bouwen).*

6. App starten:
   ```bash
   flutter run
   ```

## 🛠️ Build maken

Om een release-build te maken, gebruik een van de volgende opdrachten:

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

## 📚 Architectuur en documentatie
* [Architectuurgids (`ARCHITECTURE.md`)](../../ARCHITECTURE.md): Gedetailleerd overzicht van systeemarchitectuur, providerstatusbeheer, DAO-persistentiemodel, Google Drive Sync Coordinator, Isolate Translation Bridge en Test Quality Gates.
* [Git branching & release pipeline (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../../docs/GIT_WORKFLOW_AND_RELEASES.md): Officieel Git-vertakkingsmodel, vertakkingsbeschermingsregels, multi-platform builds (Android APK, Windows Zip, Linux AppImage/tar.gz) en geautomatiseerde bèta-pre-releases.
* [v1.7.0 Roadmap: de taaluitbreiding (`docs/plans/v1_7_0_the_lingual_expansion.md`)](../../docs/plans/v1_7_0_the_lingual_expansion.md): Volledige technische specificatie voor afzonderlijke talen, lokale REST-server, tracking van meerdere emulators, desktop-OCR en mobiele camerascanner.
* [Pipeline voor het genereren van databases (`tool/data_pipeline/locales/README.de.md`)](../../tool/data_pipeline/locales/README.nl.md): Documentatie van offline PokeAPI-gegevensvoorbereiding, scrapers, import van bijpassende ballen, indexen en databasecompilatie.
* [Ontwikkelaars- en releasetools (`tool/locales/README.de.md`)](../../tool/locales/README.nl.md): Geautomatiseerd releaseversiebeheer (`bump_version.py`), testsuites, codedekking en vertaalpijplijn (`translate_all.py`).

## 🤝 Gegevens aanvullen (Communitybijdragen)
Mis je vindplaatsen of passen de overeenkomende ballen niet? Je kunt deze gegevens aanvullen in de JSON-bestanden in de map `tool/data_pipeline/` (indien aanwezig) of direct bijdragen via Issues/Pull Requests.

Als je code, functies of bugfixes wilt bijdragen, gebruik dan de overeenkomstige issue-templates in de map `.github/ISSUE_TEMPLATE` en open een pull request op een eigen feature-branch.

## 🙏 Dankbetuigingen & Bronnen
Deze app zou niet mogelijk zijn geweest zonder deze geweldige communitybronnen:
*   [PokeAPI](https://pokeapi.co/): Basisgegevens en officiële artworks.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): Community Google Sheets als trackerbasis.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): Community-gecurateerde Excel-tabel voor de perfecte Pokéballen.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): Catch Rate-mechanieken.
*   [Google Gemini](https://gemini.google.com): AI-assistentie bij programmeren en refactoring.
* En vele anderen!

## 📄 Licentie
Dit project is gelicentieerd onder de [GNU General Public License v3.0 (GPL-3.0)](../LICENSE).

**Disclaimer:** Pokémon en alle bijbehorende namen zijn handelsmerken en © van Nintendo, Creatures Inc., en GAME FREAK inc. Dit is een gratis, niet-commercieel fanproject en staat in geen enkele verbinding met Nintendo en wordt door hen noch ondersteund noch gesponsord.
