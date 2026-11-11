# Pipeline de génération de base de données PokéVault (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | **[🇫🇷 Français](README.fr.md)** | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Ce répertoire contient l'intégralité du pipeline de données hors ligne pour la création et l'optimisation de la base de données de référence SQLite `assets/db/pokedex.sqlite` pour PokéVault.

---

## 1. Vue d'ensemble & Objectif

PokéVault fonctionne selon un principe **Offline-First**. Toutes les données statiques de la franchise (valeurs de base des Pokémon, formes alternatives, taux de capture, rubans, ensembles d’attaques apprises, lieux de capture, verrouillages Shiny, noms d’espèces multilingues et Poké Balls appropriées) sont préagrégées dans une base de données SQLite lors de la compilation et livrées avec l’application.

Cela élimine les requêtes API lentes à l'exécution et les utilisateurs peuvent utiliser l'application partout sans connexion Internet.

---

## 2. Exigences système & Configuration

- **Python 3.10 ou supérieur**
- **Git** avec support des sous-modules
- Installer les paquets Python requis :
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Initialiser les sous-modules Git :
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Sources de données & structure des répertoires

Le pipeline rassemble des données provenant de plusieurs sources fiables :

```text
tool/data_pipeline/
├── run_pipeline.py                 # All-in-One Runner: Führt alle Schritte nacheinander aus
├── build_database.py               # Hauptskript zur Datenbank-Kompilierung
├── database_constants.py           # Typen, Generationen-Mappings & ID-Konstanten
├── update_pokemon_languages.py     # Synchronisiert mehrsprachige Pokémon-Namen aus PokeAPI
├── update_evolutions_db.py         # Skript für komplexe Entwicklungsbäume
├── update_cap_locks_and_trades.py  # Skript für Kappen-, Cosplay- & Tausch-Locks
├── optimize_databases.py           # Indexierung, PRAGMA ANALYZE & VACUUM
├── api-data/                       # Git-Submodul: Offizieller PokeAPI JSON-Dump
├── ribbons_guide/                  # Git-Submodul: Ribbons.Guide Referenz
├── Legal_Matching_Pokeballs.xlsx   # Community-Excel mit legalen Ball-Kombinationen
├── custom_encounters.json          # Manuelle Ergänzungen für Fundorte
├── custom_matching_balls.json      # Manuelle Overrides für empfohlene Bälle
└── *.html                          # Offline HTML-Caches (Bulbapedia, PokéWiki, Bisafans)
```

1. **[PokeAPI](https://pokeapi.co/) (`api-data/`)** :
 - Fournissez des fichiers JSON structurés pour les données de base Pokémon, les statistiques de base, les types, les capacités, les ensembles d'apprentissage de mouvements, les noms d'espèces multilingues et les évolutions.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)** :
 - Noms allemands, groupes et descriptions de personnages (« liste de tous les groupes », « personnages »), différences de genre et Pokémon brillants.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)** :
 - Listes mondiales de rubans, échanges en jeu et Pokémon Poison pour toutes les générations (enregistrées au format HTML hors ligne).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)** :
 - Listes détaillées des cadeaux et des échanges spécifiques à l'édition de Kanto à Paldea et Z-A.
5. **Feuille de calcul communautaire (`Legal_Matching_Pokeballs.xlsx`)** :
 - Matrice détaillée de tous les Pokémon capturables par édition et correspondant à l'esthétique Pokéball.

---

## 4. Exécution rapide tout-en-un (All-in-One Runner)

Pour exécuter l'ensemble du pipeline avec tous les scripts dans le bon ordre avec une seule commande, utilisez `run_pipeline.py` :

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Ce Runner s'occupe automatiquement de :
1. `update_data.py` (mettre à jour les données externes et les sous-modules Git)
2. `build_database.py` (générer `assets/db/pokedex.sqlite` avec les données de base)
3. `update_pokemon_languages.py` (synchroniser les 10 langues de la franchise pour toutes les espèces)
4. `update_evolutions_db.py` (enrichir les arbres d'évolution)
5. `update_cap_locks_and_trades.py` (intégrer les verrous de casquette, cosplay et échanges)
6. `optimize_databases.py` (créer des index couvrants, `ANALYZE`, `VACUUM`)

---

## 5. Processus manuel (étapes individuelles)

Si certains scripts doivent être exécutés manuellement :

### Étape 1 : Mettre à jour les données brutes externes et les sous-modules
```bash
python update_data.py
```
*Télécharge les caches HTML actuels, récupère le dernier `Legal_Matching_Pokeballs.xlsx` et met à jour le sous-module `api-data`.*

### Étape 2 : Construire la base de données principale SQLite
```bash
python tool/data_pipeline/build_database.py
```
*Crée `assets/db/pokedex.sqlite`, lit tous les 1.025+ Pokémon et 250+ formes et agrège plus de 500 Shiny-Locks.*

### Étape 3 : Synchroniser les noms de Pokémon multilingues
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Lit dynamiquement toutes les langues de la franchise à partir de `lib/i18n/languages.json`, ajoute les colonnes manquantes (`name_fr`, `name_ja`, etc.) avec `ALTER TABLE` et remplit les noms à partir des JSONs hors ligne de PokeAPI.*

### Étape 4 : Enrichir les arbres de développement
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Calcule les arbres de développement, les branches et les déclencheurs.*

### Étape 5 : Intégrer les Pikachu avec casquettes, les cosplays et les échanges
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Intègre les Pikachu avec casquettes, les formes cosplay et les échanges dans `assets/db/pokedex.sqlite` et `database/pokedex.sqlite`.*

### Étape 6 : Créer des index, optimiser et VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Crée des index couvrants, exécute `ANALYZE`, `PRAGMA optimize;` et `VACUUM`.*

---

## 6. Vue d'ensemble des tableaux dans `pokedex.sqlite`

| Tableau | Descriptif | Indices importants |
|---|---|---|
| `Pokémon` | Données de base pour plus de 1 025 Pokémon, y compris 10 colonnes de langue de franchise (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `CLÉ PRIMAIRE (id)` |
| `formulaires` | Formes alternatives, Mega, G-Max, Régional | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Commandes régionales de Pokédex | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `special_dex` | Dex spéciaux (par exemple légendaires, ultra bêtes) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` | Ensembles d'apprentissage d'attaque de toutes les versions | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `pokemon_abilities` | Compétences et capacités cachées | `idx_pokemon_abilities_poke (pokemon_id)` |
| `rencontres` | Lieux et types de rencontres | `idx_encounters_poke (pokemon_id, version_group)` |
| 'évolution' | Arbres de développement complets | `CLÉ PRIMAIRE (species_id)` |
| `rubans` | Rubans de toutes générations | `CLÉ PRIMAIRE (id)` |
| `marques` | Personnages de toutes les éditions | `CLÉ PRIMAIRE (id)` |
| `shiny_locks` | Tous les verrous brillants (global et édition) | `CLÉ PRIMAIRE (pokemon_id, form_name, game_version)` |
| `legal_balls` | Poké Balls légales par Pokémon et édition | `idx_legal_balls_poke (pokemon_id, génération)` |

---

## 7. Vérification et assurance qualité

Après chaque exécution du pipeline, il faut s'assurer que la base de données générée est complète et sans erreurs :

```powershell
# 1. Datenbank-spezifische Tests ausführen
flutter test test/database/
flutter test test/db/

# 2. Shiny-Lock Tests ausführen
flutter test test/services/shiny_lock_service_test.dart
flutter test test/screens/pokemon_info/shiny_lock_ui_test.dart

# 3. Fangraten- & Matching-Ball Tests
flutter test test/screens/pokemon_info/catch_rate_calculator_test.dart
```

---

## 8. Conventions de chemin et de développement

Tous les scripts dans ce répertoire utilisent une résolution dynamique des chemins relatifs :
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Ne jamais coder en dur des chemins absolus du système d'exploitation.
- Ne pas déposer de fichiers JSON temporaires dans `assets/data/` ; toutes les données statiques doivent aller directement dans la base de données relationnelle SQLite `assets/db/pokedex.sqlite`.
