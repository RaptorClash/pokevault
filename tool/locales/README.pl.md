# 🛠️ Narzędzia deweloperskie i konserwacyjne PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | **[🇵🇱 Polski](README.pl.md)** | [🇷🇺 Русский](README.ru.md)

Ten katalog zawiera skrypty pomocnicze i automatyzacje do rozwoju, pokrycia testów, pipeline tłumaczeń, pipeline danych i zarządzania wydaniami.

---

## 📌 Przegląd narzędzi

| Skrypt / Narzędzie | Język | Opis |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Zautomatyzowane zarządzanie wersjami i budowaniem dla `pubspec.yaml` i wydań Git. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Zestaw testów jednostkowych dla `bump_version.py` (walidacja SemVer, wyrażenia regularne, flagi CLI). |
| [`translate_all.py`](../translate_all.py) | Python 3 | W pełni automatyczna pipeline tłumaczeniowa z wieloma silnikami dla stringów UI, klas slangu i dokumentacji. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Wykonuje testy z pokryciem kodu i generuje raport LCOV. |
| [`data_pipeline/`](../data_pipeline/locales/README.pl.md) | Python 3 | Scraper, importy JSON i kompilacja SQLite dla `pokedex.sqlite`. |

---

## 🌐 Zautomatyzowana linia tłumaczeń (`translate_all.py`)

Skrypt `translate_all.py` synchronizuje i tłumaczy wszystkie ciągi aplikacji (`lib/i18n/strings_*.i18n.json`), generuje rejestrację języków w Dart (`lib/i18n/language_registry.g.dart`), kompiluje Slang i tłumaczy całą dokumentację projektu do dedykowanych podfolderów `locales/`.

### Najważniejsze funkcje:
* **Bezpłatna kaskada wielosilnikowa**: Używa Bing $\rightarrow$ Google $\rightarrow$ MyMemory bez żadnych obowiązkowych kluczy API.
* **Opcjonalna obsługa DeepL**: Jeśli ustawiona jest zmienna środowiskowa `DEEPL_API_KEY`, DeepL jest używany jako priorytet.
* **Ochrona składni i symboli zastępczych**: Chroni parametry slangu (`{name}`, `{count}`), struktury liczby mnogiej ICU (`{count, plural, ...}`) i podziały wierszy (`\n`) przed błędnymi tłumaczeniami.
* **Pamięci podręcznej skrótu MD5 z funkcją zapobiegania zatruciom**: Tłumaczenia są przechowywane w `tool/.translation_cache.json` buforowany trwale; nieprawidłowe, identyczne zwroty nie są buforowane jako prawidłowe.
* **Żądanie grupowania**: Łączy ciągi w blokach po 30, aby zminimalizować żądania HTTP i uniknąć ograniczeń szybkości (HTTP 429).
* **Elastyczny język źródłowy i automatyczne wykrywanie (`--source-lang`)**: Automatycznie wykrywa (`auto`), czy plik README w języku angielskim czy niemieckim był ostatnio edytowany, lub umożliwia ręczne wymuszanie język źródłowy.
* **Przepisanie łącza Markdown i nawigacji**: Automatycznie dostosowuje łącza między podfolderami `locales/` a katalogiem głównym i generuje pasek języka w nagłówku dokumentów.

### Ważne polecenia CLI:
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

### Testy dla pipeline'u tłumaczeniowego:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 Narzędzie do podnoszenia wersji (`bump_version.py`)

Skrypt `bump_version.py` odczytuje i aktualizuje wersję w `pubspec.yaml` zgodnie z [Semantic Versioning (SemVer)](https://semver.org/) i automatycznie inkrementuje wewnętrzny numer kompilacji Flutter (`+<build>`).

### 1. Podgląd bez zmian w plikach (`--dry-run`)
Sprawdza bieżącą wersję i pokazuje, co zostało zmienione:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Przykład wyjścia:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Podnieś wersję (numer kompilacji automatycznie +1)
```bash
python tool/bump_version.py 1.6.0
```
*Zaktualizowano `version: 1.5.0+6` $
ightarrow$ `version: 1.6.0+7` w `pubspec.yaml`.*

### 3. Przypisz specyficzny numer kompilacji (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Ustawia wersję jawnie na `1.6.0+10`.*

### 4. Automatyczne tworzenie Git-Commit i Git-Tag (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Uruchamianie testów narzędzia Bump
Logika skryptu jest zabezpieczona niezależnym zestawem testów jednostkowych:
```bash
python tool/test_bump_version.py
```

---

## 📊 Pokrycie kodu (`run_coverage.ps1`)

W systemie Windows/PowerShell pokrycie testów można zmierzyć w następujący sposób:
```powershell
.\tool\run_coverage.ps1
```
Tworzy plik `coverage/lcov.info` do dalszej analizy.
