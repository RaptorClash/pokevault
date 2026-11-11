# 🛠️ Outils de développement et de maintenance PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | **[🇫🇷 Français](README.fr.md)** | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Ce répertoire contient des scripts d'aide et des automatisations pour le développement, la couverture des tests, le pipeline de traduction, la génération de notes de version, le pipeline de données et la gestion des versions.

---

## 📌 Aperçu des outils

| Script/Outil | langue | Description |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python3 | Gestion automatisée des versions et des builds pour les versions `pubspec.yaml` et Git. |
| [`test_bump_version.py`](../test_bump_version.py) | Python3 | Suite de tests unitaires pour `bump_version.py` (validation SemVer, regex, indicateurs CLI). |
| [`translate_all.py`](../translate_all.py) | Python3 | Pipeline de traduction multimoteur entièrement automatisé pour les chaînes d'interface utilisateur, les classes d'argot et la documentation. |
| [`translate_release_notes.py`](../translate_release_notes.py) | Python3 | Génère des notes de version GitHub dans les 13 langues formatées dans des listes déroulantes extensibles `<details>`. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Exécute des tests avec couverture de code et génère un rapport LCOV. |
| [`data_pipeline/`](../data_pipeline/locales/README.fr.md) | Python3 | Scrapers, importations JSON et compilation SQLite pour `pokedex.sqlite`. |

---

## 🌐 Pipeline de traduction automatisée (`translate_all.py`)

Le script `translate_all.py` synchronise et traduit tous les chaînes de l'application (`lib/i18n/strings_*.i18n.json`), génère l'enregistrement des langues Dart (`lib/i18n/language_registry.g.dart`), compile Slang et traduit toutes les documentations du projet dans des sous-dossiers `locales/` dédiés.

### Principales fonctionnalités :
* **Cascade multimoteur gratuite** : utilise Bing $\rightarrow$ Google $\rightarrow$ MyMemory sans aucune clé API obligatoire.
* **Prise en charge facultative de DeepL** : si la variable d'environnement `DEEPL_API_KEY` est définie, DeepL est utilisé en priorité.
* **Syntaxe et protection des espaces réservés** : protège les paramètres d'argot. (`{name}`, `{count}`), structures plurielles ICU (`{count, plural, ...}`) et sauts de ligne (`\n`) dus à des erreurs de traduction.
* **Cache de hachage MD5 avec anti-empoisonnement** : les traductions sont stockées dans `tool/.translation_cache.json` mises en cache de manière persistante ; les retours identiques incorrects ne sont pas mis en cache comme étant valides.
* **Request batching** : combine les chaînes en blocs de 30 pour minimiser les requêtes HTTP et éviter les limites de débit (HTTP 429).
* **Langue source flexible et détection automatique (`--source-lang`)** : détecte automatiquement (`auto`) si le README anglais ou allemand a été modifié pour la dernière fois, ou permet de forcer manuellement une source langue.
* **Markdown Link & Navigation Rewriting** : Ajuste automatiquement les liens entre les sous-dossiers `locales/` et le répertoire principal et génère la barre de langue dans l'en-tête des documents.

### Commandes CLI importantes:
```bash
# Gesamte Pipeline ausführen (UI-Strings + Dokumentationen + Slang-Kompilierung)
python tool/translate_all.py

# Vorschau ohne Dateiänderungen oder Translation-API-Aufrufe
python tool/translate_all.py --dry-run

# Nur Flutter-UI-Strings übersetzen
python tool/translate_all.py --app-only

# Nur Dokumentation übersetzen (mit automatischer Quellsprachen-Erkennung)
python tool/translate_all.py --docs-only

# Dokumentation explizit aus dem Englischen in alle Sprachen übersetzen
python tool/translate_all.py --docs-only --source-lang en

# Nur eine bestimmte Zielsprache übersetzen (z. B. Französisch)
python tool/translate_all.py --lang fr

# Multithreaded-Übersetzung mit 4 Workern
python tool/translate_all.py --workers 4
```

### Tests pour le pipeline de traduction:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 📝 Générateur de notes de version multilingues (`translate_release_notes.py`)

Le script `translate_release_notes.py` traduit automatiquement les brouillons des notes de version dans les 13 langues et les formate dans un format Markdown GitHub compact et rétractable :
- Le titre principal apparaît en haut (`# PokéVault v...`)
- Ensuite, une liste claire de toutes les 13 langues avec des drapeaux apparaît sous forme de menus déroulants `<details><summary>` rétractables
- Entièrement compatible avec le met à jour dans l'application de PokéVault (`UpdateHelper.filterReleaseNotes`)

### Utilisation :
```bash
# 1. Entwurf in tool/RELEASE_NOTES_DRAFT.md schreiben
# 2. Skript ausführen:
python tool/translate_release_notes.py

# Alternativ mit spezifischer Entwurfsdatei:
python tool/translate_release_notes.py my_draft.md -o RELEASE_NOTES.md

# Vorschau ohne Datei zu schreiben (Dry-Run):
python tool/translate_release_notes.py --dry-run
```

### Tests:
```bash
python test/tool/test_translate_release_notes.py
```

---

## 🚀 Outil de mise à jour de version (`bump_version.py`)

Le script `bump_version.py` lit et met à jour la version dans `pubspec.yaml` selon la [version sémantique (SemVer)](https://semver.org/) et incrémente automatiquement le numéro de build interne de Flutter (`+<build>`).

### 1. Aperçu sans modification de fichier (`--dry-run`)
Vérifie la version actuelle et affiche ce qui serait modifié :
```bash
python tool/bump_version.py 1.6.0 --dry-run
```

### 2. Augmenter la version (Numéro de build +1 automatiquement)
```bash
python tool/bump_version.py 1.6.0
```

### 3. Attribuer un numéro de build spécifique (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```

### 4. Créer automatiquement un commit Git et un tag Git (`--commit` & `--tag`)
```bash
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Exécuter des tests pour l'outil Bump
```bash
python tool/test_bump_version.py
```

---

## 📊 Couverture du code (`run_coverage.ps1`)

Sous Windows/PowerShell, la couverture de test peut être mesurée comme suit :
```powershell
.\tool\run_coverage.ps1
```
Crée le fichier `coverage/lcov.info` pour une analyse ultérieure.
