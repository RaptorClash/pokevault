# PokéVault конвейер генерации базы данных (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | **[🇷🇺 Русский](README.ru.md)**

Этот каталог содержит полную оффлайн-пайплайн данных для создания и оптимизации справочной базы данных SQLite `assets/db/pokedex.sqlite` для PokéVault.

---

## 1. Обзор и цель

PokéVault работает по принципу **Offline-First**. Все статические данные франшизы (базовые значения покемонов, альтернативные формы, шансы на поимку, ленты, наборы изучаемых атак, места обитания, Shiny-Locks, многоязычные названия видов и подходящие шары) предварительно агрегируются во время сборки в базе данных SQLite и поставляются вместе с приложением.

Таким образом, медленные запросы к API во время выполнения исключены, и пользователи могут использовать приложение везде без подключения к интернету.

---

## 2. Системные требования и настройка

- **Python 3.10 или выше**
- **Git** с поддержкой субмодулей
- Установить необходимые пакеты Python:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Инициализировать субмодули Git:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Источники данных и структура каталогов

Конвейер объединяет данные из нескольких доверенных источников:

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

1. **[PokeAPI](https://pokeapi.co/) (`api-data/`)**:
 — предоставление структурированных файлов JSON для основных данных покемонов, базовой статистики, типов, способностей, наборов обучения движениям, многоязычных названий видов и эволюции.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - немецкие имена, группы и описания персонажей («список всех групп», «персонажи»), гендерные различия и блестящие покемоны.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 — глобальные списки лент, внутриигровые обмены и ядовитые покемоны для всех поколений (сохраняются в автономном формате HTML).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - Подробные списки подарков и сделок для конкретных изданий от Канто до Палдеа и Z-A.
5. **Таблица сообщества (`Legal_Matching_Pokeballs.xlsx`)**:
 — Подробная таблица всех пойманных покемонов каждого выпуска и соответствующего внешнего вида Pokéball.

---

## 4. Быстрое выполнение всего комплекса (All-in-One Runner)

Чтобы выполнить весь конвейер со всеми скриптами в правильном порядке одной командой, используйте `run_pipeline.py`:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Этот Runner автоматически заботится о следующем:
1. `update_data.py` (обновление внешних данных и Git-подмодулей)
2. `build_database.py` (генерация `assets/db/pokedex.sqlite` с базовыми данными)
3. `update_pokemon_languages.py` (синхронизация всех 10 языков франшизы для всех видов)
4. `update_evolutions_db.py` (обогащение деревьев эволюций)
5. `update_cap_locks_and_trades.py` (внесение ограничений по кепкам, косплею и обменам)
6. `optimize_databases.py` (создание covering-индексов, `ANALYZE`, `VACUUM`)

---

## 5. Ручной процесс (отдельные шаги)

Если отдельные скрипты должны выполняться вручную:

### Шаг 1: Обновление внешних исходных данных и сабмодулей
```bash
python update_data.py
```
*Загружает текущие HTML-кэши, получает последнюю версию `Legal_Matching_Pokeballs.xlsx` и обновляет сабмодуль `api-data` до последней версии.*

### Шаг 2: Создание основной базы данных SQLite
```bash
python tool/data_pipeline/build_database.py
```
*Создает `assets/db/pokedex.sqlite`, считывает все 1.025+ покемонов и 250+ форм и агрегирует более 500 Shiny-Locks.*

### Шаг 3: Синхронизация многоязычных названий покемонов
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Динамически считывает все языки франшизы из `lib/i18n/languages.json`, добавляет отсутствующие столбцы (`name_fr`, `name_ja` и т.д.) с помощью `ALTER TABLE` и заполняет названия из оффлайн JSON файлов PokeAPI.*

### Шаг 4: Обогащение деревьев развития
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Вычисляет деревья развития, ветвления и триггеры.*

### Шаг 5: Внесение шапок, косплей- и обменных форм
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Вносит шапки-Пикачу, косплей-формы и обмены в `assets/db/pokedex.sqlite` и `database/pokedex.sqlite`.*

### Шаг 6: Создание индексов, оптимизация и VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Создает покрывающие индексы, выполняет `ANALYZE`, `PRAGMA optimize;` и `VACUUM`.*

---

## 6. Обзор таблиц в `pokedex.sqlite`

| Стол | Описание | Важные индексы |
|---|---|---|
| `покемон` | Основные данные для всех более чем 1025 покемонов, включая 10 языковых столбцов франшизы (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `ПЕРВИЧНЫЙ КЛЮЧ (id)` |
| `формы` | Альтернативные формы, Мега, G-Max, Региональные | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Региональные заказы покедекса | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `специальные_дексы` | Специальные дексы (например, легендарные, ультра-чудовища) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` | Наборы обучения атакам всех версий | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `pokemon_abilities` | Навыки и скрытые способности | `idx_pokemon_abilities_poke (pokemon_id)` |
| `встречи` | Локации и типы встреч | `idx_encounters_poke (pokemon_id, version_group)` |
| `эволюция` | Полные деревья развития | `ПЕРВИЧНЫЙ КЛЮЧ (species_id)` |
| `ленты` | Ленты всех поколений | `ПЕРВИЧНЫЙ КЛЮЧ (id)` |
| `знаки` | Персонажи всех выпусков | `ПЕРВИЧНЫЙ КЛЮЧ (id)` |
| `shiny_locks` | Все блестящие замки (глобальное издание и издание) | `ПЕРВИЧНЫЙ КЛЮЧ (pokemon_id, form_name, game_version)` |
| `юридические_шарики` | Легальные покеболы для Pokémon & Edition | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Верификация и обеспечение качества

После каждого выполнения конвейера необходимо убедиться, что сгенерированная база данных полная и без ошибок:

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

## 8. Конвенции по путям и разработке

Все скрипты в этом каталоге используют динамическое, относительное разрешение путей:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Никогда не жестко кодировать абсолютные пути операционной системы.
- Не храните временные JSON-файлы в `assets/data/`; все статические данные должны находиться непосредственно в реляционной базе данных SQLite `assets/db/pokedex.sqlite`.
