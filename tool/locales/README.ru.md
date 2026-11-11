# 🛠️ Инструменты разработчика и обслуживания PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | **[🇷🇺 Русский](README.ru.md)**

Этот каталог содержит вспомогательные скрипты и автоматизации для разработки, покрытия тестами, конвейера перевода, конвейера данных и управления выпуском.

---

## 📌 Обзор инструментов

| Скрипт / Инструмент | Язык | Описание |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Автоматическое управление версиями и сборками для `pubspec.yaml` и релизов Git. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Набор модульных тестов для `bump_version.py` (проверка SemVer, Regex, CLI-флаги). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Полностью автоматическая много-движковая система перевода для UI-строк, классов сленга и документации. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Выполняет тесты с покрытием кода и генерирует отчет LCOV. |
| [`data_pipeline/`](../data_pipeline/locales/README.ru.md) | Python 3 | Скрейпер, импорт JSON и компиляция в SQLite для `pokedex.sqlite`. |

---

## 🌐 Автоматизированный конвейер перевода (`translate_all.py`)

Скрипт `translate_all.py` синхронизирует и переводит все строки приложения (`lib/i18n/strings_*.i18n.json`), генерирует регистрацию языков Dart (`lib/i18n/language_registry.g.dart`), компилирует Slang и переводит всю документацию проекта в отдельные подкаталоги `locales/`.

### Ключевые особенности:
* **Бесплатный каскад с несколькими механизмами**: использует Bing $\rightarrow$ Google $\rightarrow$ MyMemory без каких-либо обязательных ключей API.
* **Дополнительная поддержка DeepL**: если установлена переменная среды `DEEPL_API_KEY`, DeepL используется в качестве приоритета.
* **Синтаксис и заполнитель Защита**: защищает сленговые параметры (`{name}`, `{count}`), структуры множественного числа ICU (`{count, plural, ...}`) и разрывы строк (`\n`) от неправильных переводов.
* **Хеш-кэш MD5 с защитой от отравления**: переводы хранятся в `tool/.translation_cache.json` и постоянно кэшируются; неправильные идентичные возвраты не кэшируются как действительные.
* **Пакетирование запросов**: объединяет строки в блоки по 30, чтобы минимизировать HTTP-запросы и избежать ограничений скорости (HTTP 429).
* **Гибкий исходный язык и автоматическое определение (`--source-lang`)**: автоматически определяет (`auto`), английский или немецкий README последний раз редактировался, или позволяет вручную принудительно определить исходный язык.
* **Ссылки Markdown и переписывание навигации**: автоматически настраивает связи между подпапками `locales/` и основным каталогом и создает языковую панель в заголовке документов.

### Важные команды CLI:
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

### Тесты для конвейера перевода:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 Инструмент увеличения версии (`bump_version.py`)

Скрипт `bump_version.py` читает и обновляет версию в `pubspec.yaml` по [Semantic Versioning (SemVer)](https://semver.org/) и автоматически увеличивает внутренний номер сборки Flutter (`+<build>`).

### 1. Предварительный просмотр без изменений файлов (`--dry-run`)
Проверяет текущую версию и показывает, что было бы изменено:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Пример вывода:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Повышение версии (номер сборки автоматически +1)
```bash
python tool/bump_version.py 1.6.0
```
*Обновлено `version: 1.5.0+6` $
ightarrow$ `version: 1.6.0+7` в `pubspec.yaml`.*

### 3. Присвоение конкретного номера сборки (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Устанавливает версию явно на `1.6.0+10`.*

### 4. Автоматическое создание Git-коммита и Git-тега (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Выполнение тестов для инструмента Bump
Логика скрипта обеспечена самостоятельным набором модульных тестов:
```bash
python tool/test_bump_version.py
```

---

## 📊 Покрытие кода (`run_coverage.ps1`)

В Windows/PowerShell измерение покрытия тестов может выполняться следующим образом:
```powershell
.\tool\run_coverage.ps1
```
Создаёт файл `coverage/lcov.info` для дальнейшего анализа.
