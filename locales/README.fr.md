# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | **[🇫🇷 Français](README.fr.md)** | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** est une application compagnon complète et entièrement personnalisable pour les Dresseurs de Pokémon, les Collectionneurs et les Chasseurs de Shiny, développée avec Flutter. Que vous visiez un Dex Régional, un Dex National, un Dex de Formes ou un Dex Shiny – PokéVault vous aide à suivre vos progrès facilement et fournit l'ensemble d'outils ultime pour vos chasses aux shiny.

[![CI Quality Gate](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml/badge.svg)](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)

## ✨ Fonctionnalités

* **Gestion de Dex multiples :** Créez autant de trackers que nécessaire pour différents jeux, générations ou défis personnalisés.
* **Suivi approfondi des formulaires :** Prise en charge complète des formulaires régionaux, Mega Evolutions, Gigantamax et des formulaires spéciaux (Alcremie, Vivillon, Unown, etc.).
* **PC Box & List Views :** Visualisez vos Pokémon dans une grille "PC Box" classique à 30 emplacements ou dans une vue détaillée, vue de liste consultable par glisser-déposer transparent.
* **Shiny Tracking & Hunt Counter :** Suivez les Pokémon normaux et brillants séparément. Compteur Shiny Hunt intégré avec calcul des cotes en temps réel, préréglages de méthode, enregistrement des phases et minuterie avec détection de pause AFK.
* **🎖️ Cartes de complétion Dex :** Concevez, personnalisez et exportez des cartes de complétion haute résolution et des mosaïques d'illustrations pour célébrer et partager vos réalisations Dex.
* **Balles de correspondance légales :** Obtenez des recommandations organisées par la communauté pour les meilleures Poké Balls (balles de correspondance) pour les deux. variations normales et brillantes !
* **📊 Calculateur avancé du taux de capture :** Calculs précis du taux de capture couvrant chaque génération, y compris des mécanismes spéciaux pour *Pokémon Legends : Arceus* et *Pokémon Legends : Z-A*.
* **🧬 Shiny Breeding & Path Calculator :** Calcule les chaînes de reproduction en plusieurs étapes (y compris Idem et Bébé Pokémon) et affiche une probabilité précise cotes.
* **📖 Guides complets de chasse Shiny :** Instructions étape par étape pour les méthodes spécifiques à une génération (par exemple, Poké Radar, DexNav, Recettes de sandwich).
* **🎮 Guide des raccourcis et des gestes dans l'application :** Guide dédié dans les paramètres affichant les raccourcis clavier, les commandes de la souris et les gestes tactiles adaptés à la plate-forme.
* **☁️ Cloud Sync et hors ligne d'abord :** 100 % hors ligne avec une base de données SQLite locale robuste. Sauvegarde et restauration transparentes en option via votre Google Drive personnel avec résilience de fusion de correctifs au niveau du champ.
* **Personnalisation complète :** Prend en charge le mode sombre/clair et les couleurs d'accent et d'arrière-plan personnalisées.
* **Multilingue :** Entièrement disponible en 13 langues (interface utilisateur via Slang). Propose une sélection indépendante de la langue de la franchise Pokémon (par exemple, une interface utilisateur allemande avec des noms de Pokémon anglais ou japonais) dans 9 langues officielles de la franchise dans « pokedex.sqlite ».

## 📸 Captures d’écran

| Écran d'accueil | Vue boîte PC |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Détails du Pokémon & Balls correspondantes** | **Création du Pokédex & Filtres** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Commencer

### Prérequis
* [SDK Flutter](https://docs.flutter.dev/get-started/install) (dernière version stable recommandée)
* SDK Dart
* Un IDE tel que VS Code ou Android Studio

### Installation
1. Cloner le dépôt :
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Accédez au répertoire du projet :
   ```bash
   cd pokevault
   ```

3. Obtenez les dépendances :
   ```bash
   flutter pub get
   ```

4. Télécharger des données externes et initialiser les sous-modules :
   Récupérer les derniers dépôts de données et wikis utilisés par le générateur de base de données :
   ```bash
   python3 update_data.py
   ```

5. Configurer la base de données SQLite :
   *PokéVault repose sur une base de données SQLite pré-construite pour les données de référence principales des Pokémon.* 
   Exécutez le script de pipeline de données tout-en-un pour générer et optimiser `assets/db/pokedex.sqlite` :
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Sinon, exécutez avec `--skip-download` si vous avez déjà les dumps web externes et que vous voulez seulement recompiler la base de données).*

6. Exécutez l'application :
   ```bash
   flutter run
   ```

## 🛠️ Construire l'application

Pour compiler une version de production pour votre plateforme spécifique, exécutez l'une des commandes suivantes :

**Android (APK) :**
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

**Image d'application Linux :**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**Web :**
```bash
flutter build web --release
```

## 📚 Architecture et documentation
* [Guide d'architecture (`ARCHITECTURE.md`)](ARCHITECTURE.fr.md) : présentation complète du système, architecture d'état (fournisseur), modèle de persistance DAO, coordinateur de synchronisation Google Drive, pont de traduction Isolate et portes de qualité.
* [Git Workflow & Release Pipeline (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.fr.md) : modèle de branchement Git officiel, règles de protection des branches, versions multiplateformes (APK Android, Windows Zip, Linux AppImage/tar.gz) et versions bêta automatisées.
* [Feuille de route v1.7.0 : l'expansion du langage (`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md) : spécifications techniques complètes pour des langues distinctes, API REST locale, suivi multi-émulateur, OCR de bureau et scanner de caméra mobile.
* [Pipeline de générateur de base de données (`tool/data_pipeline/README.md`)](../tool/data_pipeline/locales/README.fr.md) : Documentation détaillée pour les développeurs sur l'analyse PokeAPI hors ligne, les web scrapers, les données légales Pokéball, les index et les étapes de compilation de base de données.
* [Outils de développement et de publication (`tool/README.md`)](../tool/locales/README.fr.md) : Documentation pour le remplacement automatique des versions de version (`bump_version.py`), les tests unitaires, la couverture du code et le pipeline de traduction automatisée (`translate_all.py`).

## 🤝 Données de contribution (correctifs communautaires)
Rencontres manquantes ou avez-vous de meilleures suggestions de Matching Ball ? Vous pouvez facilement ajouter ou corriger ces données dans les fichiers JSON situés dans le répertoire `tool/data_pipeline/` (le cas échéant) ou contribuer directement via Issues/Pull Requests.

Si vous souhaitez contribuer au code, aux fonctionnalités ou aux corrections de bogues, veuillez utiliser les modèles de problème appropriés dans le dossier `.github/ISSUE_TEMPLATE` et ouvrez une Pull Request sur une branche de fonctionnalités dédiée.

## 🙏 Crédits et sources
Cette application ne serait pas possible sans ces incroyables ressources communautaires :
* [PokeAPI](https://pokeapi.co/) : données de base et œuvres d'art officielles.
* [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v) : Communauté Google Sheets.
* [Boules assorties Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959) : feuille Excel organisée par la communauté pour faire correspondre les Poké Balls.
* [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate) : Mécanique du taux de capture.
* [Google Gemini](https://gemini.google.com) : Assistance de l'IA pour le codage et la refactorisation.
* Et bien d'autres !

## 📄 Licence
Ce projet est sous licence [GNU General Public License v3.0 (GPL-3.0)](../LICENSE).

**Avertissement :** Pokémon et tous les noms respectifs sont des marques déposées et © de Nintendo, Creatures Inc. et GAME FREAK inc. Il s'agit d'un projet de fan gratuit et non commercial et n'est en aucun cas affilié, approuvé ou soutenu par Nintendo.
