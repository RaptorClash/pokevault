# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | **[🇵🇱 Polski](README.pl.md)** | [🇷🇺 Русский](README.ru.md)

**PokéVault** to wszechstronny, w pełni konfigurowalny asystent dla trenerów Pokémonów, kolekcjonerów i łowców Shiny, stworzony w Flutterze. Niezależnie od tego, czy planujesz regionalny Dex, krajowy Dex, Dex form czy Dex Shiny – PokéVault pomoże ci łatwo śledzić twój postęp i dostarczy niezbędne narzędzia do polowania na Shiny.

[![CI Quality Gate](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml/badge.svg)](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![Lizenz](https://img.shields.io/badge/Lizenz-GPL--3.0-blue.svg)

## ✨ Główne funkcje

* **Zarządzanie Multi-Dex:** Twórz dowolną liczbę trackerów dla różnych gier, pokoleń lub własnych wyzwań.
* **Szczegółowe śledzenie formularzy:** Pełna obsługa form regionalnych, mega ewolucji, Gigantamax i form specjalnych (Pokusan, Vivillon, Unown itp.).
* **PC Box i widok listy:** Zobacz swoje Pokémony w klasycznej siatce „PC Box” z 30 miejscami lub w lista z możliwością przeszukiwania za pomocą płynnego przeciągania i upuszczania.
* **Błyszczący licznik śledzenia i polowań:** Śledź osobno normalne i błyszczące Pokémony. Wbudowany licznik Shiny Hunt z obliczaniem prawdopodobieństwa w czasie rzeczywistym, wyborem metod, historią faz i licznikiem sesji z wykrywaniem pauzy AFK.
* **🎖️ Karty ukończenia Dex:** Projektuj, personalizuj i eksportuj certyfikaty osiągnięć, karty statystyk i mozaiki Pokémon w wysokiej rozdzielczości, aby dzielić się swoimi postępami.
* **Pasujące kulki:** Otrzymuj rekomendacje społeczności dotyczące najlepszych Poké Balli (dla normalnych *i* błyszczące warianty)!
* **📊 Zaawansowany kalkulator współczynnika połowów:** Precyzyjne obliczanie prawdopodobieństwa złapania we wszystkich generacjach, w tym specjalne mechaniki z *Pokémon Legends: Arceus* i *Pokémon Legends: Z-A*.
* **🧬 Błyszczący kalkulator hodowli i trasy:** Oblicza wieloetapowe łańcuchy hodowlane (w tym Ditto i młode Pokémony) i wyświetla dokładne prawdopodobieństwo dla docelowego potomstwa.
* **📖 Szczegółowe, błyszczące przewodniki polowań:** Instrukcje krok po kroku dotyczące metod specyficznych dla generacji (np. PokéRadar, DexNav, przepisy na kanapki).
* **🎮 Obsługa i skróty w aplikacji Przegląd:** Własny ekran w ustawieniach ze skrótami dostosowanymi do platformy, poleceniami myszy i dotykiem gesty.
* **☁️ Synchronizacja w chmurze i przede wszystkim tryb offline:** Możliwość pracy w 100% w trybie offline dzięki solidnej lokalnej bazie danych SQLite. Opcjonalna synchronizacja za pośrednictwem prywatnego Dysku Google z odpornością na łączenie poprawek.
* **Pełna personalizacja:** Obsługuje tryb ciemny/jasny oraz konfigurowalne kolory akcentów i tła.
* **Wielojęzyczny:** W pełni dostępny w 13 językach (UI poprzez slang). Dodatkowo niezależny wybór języka franczyzy Pokémon (np. niemiecki interfejs użytkownika z angielskimi lub japońskimi nazwami Pokémon) w oparciu o 10 oficjalnych języków franczyzy w `pokedex.sqlite`.

## 📸 Zrzuty ekranu

| Ekran główny | Widok skrzynki PC |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Szczegóły Pokémonów i pasujące kule** | **Tworzenie Dexa i filtry** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Pierwsze kroki (uruchamianie lokalne)

### Wymagania
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (zalecana najnowsza stabilna wersja)
* Dart SDK
* IDE, takie jak VS Code lub Android Studio

### Instalacja
1. Sklonuj repozytorium:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Przejdź do katalogu:
   ```bash
   cd pokevault
   ```

3. Pobierz zależności:
   ```bash
   flutter pub get
   ```

4. Pobierz dane zewnętrzne i zainicjalizuj submoduły:
   Pobierz najnowsze repozytoria danych i wiki, które są potrzebne do bazy danych:
   ```bash
   python3 update_data.py
   ```

5. Generowanie i optymalizacja bazy danych SQLite:
   *PokéVault wymaga wstępnie skompilowanej bazy danych SQLite dla podstawowych danych Pokémon.* 
   Uruchom skrypt All-in-One Pipeline, aby wygenerować i zoptymalizować `assets/db/pokedex.sqlite` za pomocą jednego polecenia:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Alternatywnie uruchom z `--skip-download`, jeśli posiadasz już zewnętrzne zrzuty internetowe i chcesz jedynie odbudować bazę danych).

6. Uruchom aplikację:
   ```bash
   flutter run
   ```

## 🛠️ Utwórz build

Aby utworzyć kompilację release, użyj jednego z następujących poleceń:

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

**Sieć:**
```bash
flutter build web --release
```

## 📚 Architektura i dokumentacja
* [Przewodnik po architekturze (`ARCHITECTURE.md`)](ARCHITECTURE.pl.md): szczegółowy przegląd architektury systemu, zarządzanie stanem dostawcy, model trwałości DAO, koordynator Google Drive Sync, izolowany most translacyjny i testowanie bramek jakości.
* [Rozgałęzianie i potok wydań Git (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.pl.md): Oficjalny model rozgałęzień Git, zasady ochrony gałęzi, kompilacje wieloplatformowe (Android APK, Windows Zip, Linux AppImage/tar.gz) i zautomatyzowane wersje wstępne Beta.
* [Plan działania wersji 1.7.0: The Rozszerzenie języka (`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md): Pełna specyfikacja techniczna dla oddzielnych języków, lokalny serwer REST, śledzenie za pomocą wielu emulatorów, stacjonarny OCR i mobilny skaner aparatu.
* [Potok generowania bazy danych (`tool/data_pipeline/locales/README.de.md`)](../tool/data_pipeline/locales/README.pl.md): Dokumentacja przygotowania danych offline PokeAPI, skrobaków, importu pasujących kulek, indeksów i kompilacji baz danych.
* [Narzędzia dla programistów i wydań (`tool/locales/README.de.md`)](../tool/locales/README.pl.md): Zautomatyzowane zarządzanie wersjami wydań (`bump_version.py`), zestawami testów, pokryciem kodu i potokiem tłumaczeń (`translate_all.py`).

## 🤝 Uzupełnianie danych (Wkład społeczności)
Brakuje Ci miejsc znalezienia lub nie pasują Ci dopasowane kulki? Możesz uzupełnić te dane w plikach JSON w katalogu `tool/data_pipeline/` (jeśli istnieją) lub wnosić je bezpośrednio przez Issues/Pull Requests.

Jeśli chcesz wnosić kod, funkcje lub poprawki błędów, użyj odpowiednich szablonów zgłoszeń w folderze `.github/ISSUE_TEMPLATE` i otwórz pull request na własnym branchu funkcji.

## 🙏 Podziękowania i źródła
Ta aplikacja nie byłaby możliwa bez tych wspaniałych zasobów z naszej społeczności:
*   [PokeAPI](https://pokeapi.co/): dane podstawowe i oficjalne grafiki gatunków.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): dokumenty Google Sheets społeczności jako baza śledzenia.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): tabela Excel kuratowana przez społeczność dla idealnych Pokéballi.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): mechaniki Catch Rate.
*   [Google Gemini](https://gemini.google.com): wsparcie AI przy programowaniu i refaktoryzacji.
* I wiele innych!

## 📄 Licencja
Ten projekt jest licencjonowany na podstawie [GNU General Public License v3.0 (GPL-3.0)](../LICENSE).

**Wyłączenie odpowiedzialności:** Pokémon i wszystkie powiązane nazwy są znakami towarowymi i © Nintendo, Creatures Inc. oraz GAME FREAK inc. Jest to bezpłatny, niekomercyjny projekt fanowski i w żaden sposób nie jest powiązany z Nintendo ani przez nich wspierany czy sponsorowany.
