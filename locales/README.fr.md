# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | **[🇫🇷 Français](README.fr.md)** | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** est un compagnon complet et entièrement personnalisable pour les dresseurs de Pokémon, les collectionneurs et les chasseurs de Shiny, développé avec Flutter. Que vous planifiiez un Dex régional, un Dex national, un Dex de formes ou un Dex Shiny – PokéVault vous aide à suivre facilement vos progrès et vous fournit les outils nécessaires pour votre chasse aux Shiny.

[![CI Quality Gate](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml/badge.svg)](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![Lizenz](https://img.shields.io/badge/Lizenz-GPL--3.0-blue.svg)

## ✨ Fonctions principales

* **Gestion Multi-Dex :** Créez autant de trackers que vous le souhaitez pour différents jeux, générations ou vos propres défis.
* **Suivi détaillé des formulaires :** Prise en charge complète des formes régionales, méga évolutions, Gigantamax et formes spéciales (Pokusan, Vivillon, Unown, etc.).
* **Boîte PC et vue liste :** Visualisez vos Pokémon dans la grille classique à 30 emplacements "PC Box" ou dans une liste consultable avec glissement transparent & drop.
* **Shiny Tracking & Hunt Counter :** Suivez les Pokémon normaux et brillants séparément. Compteur Shiny Hunt intégré avec calcul de probabilité en temps réel, sélection de méthode, historique des phases et minuterie de session avec détection de pause AFK.
* **🎖️ Cartes de complétion Dex :** Concevez, personnalisez et exportez des certificats de réussite haute résolution, des cartes statistiques et des mosaïques Pokémon pour partager vos progrès.
* **Balles correspondantes :** Recevez des recommandations organisées par la communauté pour les meilleures Poké Balls (pour les Poké Balls normales *et* brillantes). variantes) !
* **📊 Calculateur avancé du taux de capture :** Calcul précis de la probabilité de capture sur toutes les générations, y compris les mécanismes spéciaux de *Pokémon Legends : Arceus* et *Pokémon Legends : Z-A*.
* **🧬 Calculateur d'élevage et d'itinéraire brillant :** Calcule les chaînes de reproduction à plusieurs étapes (y compris Idem et les bébés Pokémon) et affiche les probabilités exactes pour la cible offspring.
* **📖 Guides de chasse brillants détaillés :** Instructions étape par étape pour les méthodes spécifiques à la génération (par exemple, PokéRadar, DexNav, recettes de sandwich).
* **🎮 Fonctionnement et raccourcis dans l'application Présentation :** Propre écran dans les paramètres avec des raccourcis adaptatifs à la plate-forme, des commandes de souris et des gestes tactiles.
* **☁️ Cloud Sync & Hors ligne d'abord :** 100 % hors ligne avec une base de données SQLite locale robuste. Synchronisation facultative via votre Google Drive privé avec résilience de fusion de correctifs.
* **Personnalisation complète :** Prend en charge le mode sombre/clair et les couleurs d'accent et d'arrière-plan personnalisables.
* **Multilingue :** Entièrement disponible en 13 langues (UI via Slang). De plus, sélection indépendante de la langue de la franchise Pokémon (par exemple, interface utilisateur allemande avec noms de Pokémon anglais ou japonais) basée sur 10 langues officielles de la franchise dans « pokedex.sqlite ».

## 📸 Captures d’écran

| Écran d'accueil | Vue boîte PC |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Détails des Pokémon & Balles correspondantes** | **Création de Dex & Filtres** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Premiers pas (Exécuter localement)

### Prérequis
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version stable actuelle recommandée)
* SDK Dart
* Un IDE comme VS Code ou Android Studio

### Installation
1. Cloner le dépôt :
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Changer de répertoire :
   ```bash
   cd pokevault
   ```

3. Télécharger les dépendances :
   ```bash
   flutter pub get
   ```

4. Télécharger des données externes et initialiser les sous-modules :
   Téléchargez les dépôts de données et les wikis les plus récents nécessaires pour la base de données :
   ```bash
   python3 update_data.py
   ```

5. Générer et optimiser la base de données SQLite :
   *PokéVault nécessite une base de données SQLite précompilée pour les données de base des Pokémon.* 
   Exécutez le script tout-en-un pour générer et optimiser `assets/db/pokedex.sqlite` en une seule commande :
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Alternativement, exécutez avec `--skip-download` si vous possédez déjà les dumps Web externes et souhaitez uniquement reconstruire la base de données).*

6. Lancer l'application :
   ```bash
   flutter run
   ```

## 🛠️ Créer une build

Pour créer une version de production, utilisez l'une des commandes suivantes :

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

**Linux AppImage:**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**Web:**
```bash
flutter build web --release
```

## 📚 Architecture et documentation
* [Guide d'architecture (`ARCHITECTURE.md`)](../../ARCHITECTURE.md) : aperçu détaillé de l'architecture du système, de la gestion de l'état du fournisseur, du modèle de persistance DAO, du coordinateur de synchronisation Google Drive, du pont de traduction isolé et des portes de qualité de test.
* [Branchage Git et pipeline de publication (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../../docs/GIT_WORKFLOW_AND_RELEASES.md) : modèle de branchement Git officiel, règles de protection des branches, versions multiplateformes (APK Android, Windows Zip, Linux AppImage/tar.gz) et pré-versions bêta automatisées.
* [Feuille de route v1.7.0 : l'expansion du langage (`docs/plans/v1_7_0_the_lingual_expansion.md`)](../../docs/plans/v1_7_0_the_lingual_expansion.md) : Spécifications techniques complètes pour les langues séparées, le serveur REST local, le suivi multi-émulateur, l'OCR de bureau et le scanner de caméra mobile.
* [Pipeline de génération de base de données (`tool/data_pipeline/locales/README.de.md`)](../../tool/data_pipeline/locales/README.fr.md) : Documentation sur la préparation des données PokeAPI hors ligne, les grattoirs, l'importation de balles correspondantes, les index et la compilation de bases de données.
* [Outils de développement et de publication (`tool/locales/README.de.md`)](../../tool/locales/README.fr.md) : gestion automatisée des versions (`bump_version.py`), suites de tests, couverture de code et pipeline de traduction (`translate_all.py`).

## 🤝 Compléter les données (Contributions de la communauté)
Te manquent des lieux ou les boules correspondantes ne conviennent pas ? Tu peux compléter ces données dans les fichiers JSON du répertoire `tool/data_pipeline/` (si disponibles) ou contribuer directement via des Issues/Pull Requests.

Si tu souhaites contribuer du code, des fonctionnalités ou des corrections de bugs, utilise s'il te plaît les modèles de problème correspondants dans le dossier `.github/ISSUE_TEMPLATE` et ouvre une demande de tirage sur une branche de fonctionnalité distincte.

## 🙏 Remerciements & Sources
Cette application n'aurait pas été possible sans ces excellentes ressources de la communauté :
*   [PokeAPI](https://pokeapi.co/) : données de base et illustrations officielles.
*   [Inspiration pour Living Dex](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v) : Google Sheets de la communauté comme base de suivi.
*   [Guide des Balls correspondantes](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959) : tableau Excel curaté par la communauté pour les Poké Balls parfaits.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate) : mécanismes de taux de capture.
*   [Google Gemini](https://gemini.google.com) : assistance IA pour programmer et refactoriser.
* Et beaucoup d'autres!

## 📄 Licence
Ce projet est sous licence [GNU General Public License v3.0 (GPL-3.0)](../LICENSE).

**Avertissement :** Pokémon et tous les noms associés sont des marques et © de Nintendo, Creatures Inc., et GAME FREAK inc. Il s'agit d'un projet de fans gratuit et non commercial et n'a aucun lien avec Nintendo et n'est ni soutenu ni sponsorisé par eux.
