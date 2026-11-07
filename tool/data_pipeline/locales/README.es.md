# Tubería de generación de base de datos de PokéVault (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | **[🇪🇸 Español](README.es.md)** | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Este directorio contiene la canalización de datos completa sin conexión para la creación y optimización de la base de datos de referencia SQLite `assets/db/pokedex.sqlite` para PokéVault.

---

## 1. Resumen y objetivos

PokéVault trabaja según un principio **Offline-First**. Todos los datos estáticos de la franquicia (valores base de Pokémon, formas alternativas, tasas de captura, cintas, sets de aprendizaje de ataques, ubicaciones, bloqueos de shiny, nombres de especies multilingües y Pokébolas correspondientes) se preagregan en una base de datos SQLite en tiempo de compilación y se entregan con la aplicación.

De este modo se eliminan las consultas lentas de la API en tiempo de ejecución y los usuarios pueden usar la aplicación en cualquier lugar sin conexión a Internet.

---

## 2. Requisitos del sistema y configuración

- **Python 3.10 o superior**
- **Git** con soporte para submódulos
- Instalar los paquetes de Python necesarios:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Inicializar submódulos de Git:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Fuentes de datos y estructura del directorio

La canalización combina datos de varias fuentes confiables:

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
 - Proporciona archivos JSON estructurados para datos maestros de Pokémon, estadísticas básicas, tipos, habilidades, conjuntos de aprendizaje de movimientos, nombres de especies multilingües y evoluciones.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - Nombres alemanes, bandas y descripciones de personajes ("lista de todas las bandas", "personajes"), diferencias de género y Pokémon shiny.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 - Listas globales de listones, intercambios en el juego y Pokémon venenosos de todas las generaciones (guardados como HTML sin conexión).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - Listas detalladas de obsequios e intercambios específicos de la edición de Kanto a Paldea y Z-A.
5. **Hoja de cálculo comunitaria (`Legal_Matching_Pokeballs.xlsx`)**:
 - Matriz detallada de todos los Pokémon capturables por edición y estética de Pokéball coincidente.

---

## 4. Ejecución rápida completa (Ejecutor todo en uno)

Para ejecutar toda la canalización con todos los scripts en el orden correcto con un solo comando, usa `run_pipeline.py`:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Este Runner se encarga automáticamente de:
1. `update_data.py` (actualizar datos externos y submódulos de Git)
2. `build_database.py` (generar `assets/db/pokedex.sqlite` con datos básicos)
3. `update_pokemon_languages.py` (sincronizar los 10 idiomas de la franquicia para todas las especies)
4. `update_evolutions_db.py` (enriquecer los árboles de evolución)
5. `update_cap_locks_and_trades.py` (agregar bloqueos de gorras, cosplay y intercambios)
6. `optimize_databases.py` (crear índices de cobertura, `ANALYZE`, `VACUUM`)

---

## 5. Procedimiento manual (pasos individuales)

En caso de que se desee ejecutar algunos scripts manualmente:

### Paso 1: Actualizar datos en bruto externos y submódulos
```bash
python update_data.py
```
*Descarga las cachés HTML actuales, extrae el último `Legal_Matching_Pokeballs.xlsx` y actualiza el submódulo `api-data` a la versión más reciente.*

### Paso 2: Construir la base de datos principal de SQLite
```bash
python tool/data_pipeline/build_database.py
```
*Crea `assets/db/pokedex.sqlite`, lee más de 1.025 Pokémon y más de 250 formas y agrega más de 500 bloqueos de Shiny.*

### Paso 3: Sincronizar nombres de Pokémon multilingües
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Lee dinámicamente todos los idiomas de la franquicia desde `lib/i18n/languages.json`, agrega columnas faltantes (`name_fr`, `name_ja`, etc.) mediante `ALTER TABLE` y llena los nombres a partir de los JSON de PokeAPI offline.*

### Paso 4: Enriquecer árboles de desarrollo
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Calcula árboles de desarrollo, ramificaciones y desencadenantes.*

### Paso 5: Añadir Gorros, Cosplay y Cambios
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Añade Pikachu con gorros, formas de cosplay e intercambios en `assets/db/pokedex.sqlite` y `database/pokedex.sqlite`.*

### Paso 6: Crear índices, optimizar y VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Crea índices de cobertura, ejecuta `ANALYZE`, `PRAGMA optimize;` y `VACUUM`.*

---

## 6. Vista general de tablas en `pokedex.sqlite`

| Mesa | Descripción | Índices importantes |
|---|---|---|
| `pokémon` | Datos básicos para los más de 1025 Pokémon, incluidas 10 columnas de idiomas de franquicia (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `CLAVE PRIMARIA (id)` |
| `formularios` | Formas alternativas, Mega, G-Max, Regional | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | Órdenes regionales de Pokédex | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `índices_especiales` | Dexes especiales (por ejemplo, legendarios, ultrabestias) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `movimientos_pokemon` | Conjuntos de aprendizaje de ataques de todas las versiones | `idx_pokemon_moves_poke (pokemon_id, grupo_versión)` |
| `habilidades_pokemon` | Habilidades y Habilidades Ocultas | `idx_pokemon_abilities_poke (pokemon_id)` |
| `encuentros` | Ubicaciones y tipos de encuentros | `idx_encuentros_poke (pokemon_id, grupo_versión)` |
| `evolución` | Árboles de desarrollo completo | `CLAVE PRIMARIA (id_especie)` |
| `cintas` | Cintas de todas las generaciones | `CLAVE PRIMARIA (id)` |
| `marcas` | Personajes de todas las ediciones | `CLAVE PRIMARIA (id)` |
| `bloques_brillantes` | Todos los candados brillantes (global y edición) | `CLAVE PRIMARIA (pokemon_id, nombre_formulario, versión_juego)` |
| `bolas_legales` | Poké Balls legales por Pokémon y edición | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Verificación y aseguramiento de la calidad

Después de cada ejecución de la canalización, se debe asegurar que la base de datos generada esté completa y sin errores:

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

## 8. Convenciones de rutas y desarrollo

Todos los scripts en este directorio utilizan resolución de rutas relativa y dinámica:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Nunca codificar rutas absolutas del sistema operativo.
- No colocar archivos JSON temporales en `assets/data/`; todos los datos estáticos deben ir directamente en la base de datos relacional SQLite `assets/db/pokedex.sqlite`.
