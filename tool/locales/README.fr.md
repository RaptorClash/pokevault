# 🛠️ Outils de développement et de maintenance PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | **[🇫🇷 Français](README.fr.md)** | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Ce répertoire contient des scripts d'aide et des automatisations pour le développement, la couverture des tests, le pipeline de traduction, le pipeline de données et la gestion des versions.

---

## 📌 Aperçu des outils

| Script / Outil | Langue | Description |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Gestion automatisée des versions et des builds pour `pubspec.yaml` et les releases Git. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Suite de tests unitaires pour `bump_version.py` (validation SemVer, Regex, options CLI). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Pipeline de traduction multi-moteurs entièrement automatisée pour les chaînes UI, classes d'argot et documentations. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Exécute les tests avec couverture du code et génère un rapport LCOV. |
| [`data_pipeline/`](../../data_pipeline/locales/README.fr.md) | Python 3 | Scraper, importations JSON et compilation SQLite pour `pokedex.sqlite`. |

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

## 🚀 Outil de mise à jour de version (`bump_version.py`)

Le script `bump_version.py` lit et met à jour la version dans `pubspec.yaml` selon la [version sémantique (SemVer)](https://semver.org/) et incrémente automatiquement le numéro de build interne de Flutter (`+<build>`).

### 1. Aperçu sans modifications de fichier (`--dry-run`)
Vérifie la version actuelle et affiche ce qui serait modifié :
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Exemple de sortie :*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Augmenter la version (numéro de build +1 automatique)
```bash
python tool/bump_version.py 1.6.0
```
*Mis à jour `version: 1.5.0+6` $ightarrow$ `version: 1.6.0+7` dans `pubspec.yaml`.*

### 3. Attribuer un numéro de build spécifique (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Définit explicitement la version sur `1.6.0+10`.*

### 4. Créer automatiquement un commit Git et un tag Git (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Exécuter les tests pour l'outil Bump
La logique du script est sécurisée par une suite de tests unitaires autonome :
```bash
python tool/test_bump_version.py
```

---

## 📊 Couverture du code (`run_coverage.ps1`)

Sous Windows/PowerShell, la couverture des tests peut être mesurée comme suit :
```powershell
.\tool\run_coverage.ps1
```
Crée le fichier `coverage/lcov.info` pour une analyse ultérieure.
