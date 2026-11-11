# 🛠️ Herramientas de desarrollo y mantenimiento de PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | **[🇪🇸 Español](README.es.md)** | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Este directorio contiene scripts de ayuda y automatizaciones para desarrollo, cobertura de pruebas, canal de traducción, canal de datos y gestión de versiones.

---

## 📌 Resumen de las herramientas

| Script / Herramienta | Lenguaje | Descripción |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Gestión automatizada de versiones y compilaciones para `pubspec.yaml` y lanzamientos de Git. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Suite de pruebas unitarias para `bump_version.py` (validación SemVer, expresiones regulares, flags de CLI). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Pipeline de traducción multi-motor totalmente automática para cadenas de UI, clases de jerga y documentación. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Ejecuta pruebas con cobertura de código y genera un informe LCOV. |
| [`data_pipeline/`](../data_pipeline/locales/README.es.md) | Python 3 | Scraper, importaciones JSON y compilación SQLite para `pokedex.sqlite`. |

---

## 🌐 Canal de traducción automatizado (`translate_all.py`)

El script `translate_all.py` sincroniza y traduce todas las cadenas de la aplicación (`lib/i18n/strings_*.i18n.json`), genera el registro de idiomas de Dart (`lib/i18n/language_registry.g.dart`), compila Slang y traduce toda la documentación del proyecto en subcarpetas dedicadas `locales/`.

### Características clave:
* **Cascada multimotor gratuita**: utiliza Bing $\rightarrow$ Google $\rightarrow$ MyMemory sin claves API obligatorias.
* **Compatibilidad opcional con DeepL**: si la variable de entorno `DEEPL_API_KEY` está configurada, DeepL se utiliza como prioridad.
* **Protección de sintaxis y marcadores de posición**: protege los parámetros de jerga (`{name}`, `{count}`), estructuras plurales ICU (`{count, plural, ...}`) y saltos de línea (`\n`) de traducciones erróneas.
* **Caché hash MD5 con antienvenenamiento**: Las traducciones se almacenan en `tool/.translation_cache.json` almacenadas en caché de forma persistente; Las devoluciones idénticas incorrectas no se almacenan en caché como válidas.
* **Solicitud por lotes**: combina cadenas en bloques de 30 para minimizar las solicitudes HTTP y evitar límites de velocidad (HTTP 429).
* **Idioma de origen flexible y detección automática (`--source-lang`)**: Detecta automáticamente ("auto`) si el README en inglés o alemán se editó por última vez, o permite forzar manualmente una fuente language.
* **Markdown Link & Navigation Rewriting**: ajusta automáticamente los enlaces entre las subcarpetas `locales/` y el directorio principal y genera la barra de idioma en el encabezado de los documentos.

### Comandos importantes de CLI:
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

### Pruebas para la canalización de traducción:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 Herramienta de Actualización de Versión (`bump_version.py`)

El script `bump_version.py` lee y actualiza la versión en `pubspec.yaml` según [Versionado Semántico (SemVer)](https://semver.org/) e incrementa automáticamente el número de compilación interno de Flutter (`+<build>`).

### 1. Vista previa sin cambios en archivos (`--dry-run`)
Verifica la versión actual y muestra lo que se cambiaría:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Ejemplo de salida:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Aumentar la versión (Número de compilación automáticamente +1)
```bash
python tool/bump_version.py 1.6.0
```
*Actualizado `version: 1.5.0+6` $
ightarrow$ `version: 1.6.0+7` en `pubspec.yaml`.*

### 3. Asignar número de compilación específico (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Establece la versión explícitamente en `1.6.0+10`.*

### 4. Crear automáticamente Git-Commit y Git-Tag (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Ejecutar pruebas para la herramienta Bump
La lógica del script está asegurada mediante una suite de pruebas unitarias independiente:
```bash
python tool/test_bump_version.py
```

---

## 📊 Cobertura de Código (`run_coverage.ps1`)

En Windows/PowerShell, la cobertura de prueba se puede medir de la siguiente manera:
```powershell
.\tool\run_coverage.ps1
```
Genera el archivo `coverage/lcov.info` para un análisis posterior.
