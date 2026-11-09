# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | **[🇪🇸 Español](README.es.md)** | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** es una aplicación complementaria completa y totalmente personalizable para Entrenadores de Pokémon, Completionists y cazadores de Shiny, construida con Flutter. Ya sea que estés apuntando a un Dex Regional, un Dex Nacional, un Dex de Formas o un Dex de Shiny, PokéVault te ayuda a hacer seguimiento de tu progreso con facilidad y proporciona el conjunto de herramientas definitivo para tus cacerías de shiny.

__BLOQUE_DE_INSIGNIA_0__
__BLOQUE_DE_INSIGNIA_1__
__BLOQUE_DE_INSIGNIA_2__
__BLOQUE_DE_INSIGNIA_3__
__BLOQUE_DE_INSIGNIA_4__

## ✨ Características

* **Gestión de Dex múltiple:** Crea tantos rastreadores como necesites para diferentes juegos, generaciones o desafíos personalizados.
* **Seguimiento de forma profunda:** Soporte completo para formas regionales, megaevoluciones, Gigantamax y formas especiales (Alcremie, Vivillon, Unown, etc.).
* **Vistas de lista y caja de PC:** Visualiza tus Pokémon en una cuadrícula clásica de "Caja de PC" de 30 espacios o en una vista detallada, vista de lista con capacidad de búsqueda con arrastrar y soltar sin interrupciones.
* **Seguimiento brillante y contador de caza:** Rastree Pokémon normales y brillantes por separado. Contador Shiny Hunt integrado con cálculo de probabilidades en tiempo real, métodos preestablecidos, registro de fases y temporizador con detección de pausa AFK.
* **🎖️ Tarjetas de finalización de Dex:** Diseña, personaliza y exporta tarjetas de finalización de alta resolución y mosaicos artísticos para celebrar y compartir tus logros de Dex.
* **Bolas coincidentes legales:** Obtén recomendaciones seleccionadas por la comunidad para las mejores Poké Balls (Bolas coincidentes) para ambos ¡Variaciones normales y shiny!
* **📊 Calculadora avanzada de tasa de captura:** Cálculos precisos de tasa de captura que abarcan cada generación, incluidas mecánicas especiales para *Pokémon Legends: Arceus* y *Pokémon Legends: Z-A*.
* **🧬 Shiny Breeding & Path Calculator:** Calcula cadenas de reproducción de varios pasos (incluidos Ditto y Baby Pokémon) y muestra la probabilidad precisa odds.
* **📖 Guías completas de caza de Shiny:** Instrucciones paso a paso para métodos específicos de cada generación (por ejemplo, Poké Radar, DexNav, Recetas de sándwich).
* **🎮 Guía de gestos y atajos en la aplicación:** Guía dedicada en Configuración que muestra atajos de teclado, controles de mouse y gestos táctiles adaptables a la plataforma.
* **☁️ Sincronización en la nube y sin conexión primero:** 100% sin conexión con una sólida base de datos SQLite local. Copia de seguridad y restauración integradas opcionales a través de su Google Drive personal con resistencia a la fusión de parches a nivel de campo.
* **Personalización completa:** Admite modo oscuro/claro y colores de fondo y acento personalizados.
* **Multilingüe:** Totalmente disponible en 13 idiomas (UI a través de Slang). Incluye selección independiente del idioma de la franquicia Pokémon (por ejemplo, interfaz de usuario en alemán con nombres de Pokémon en inglés o japonés) en 9 idiomas oficiales de la franquicia en `pokedex.sqlite`.

## 📸 Capturas de pantalla

| Pantalla de Inicio | Vista de Caja de PC |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Detalles de Pokémon & Bolas Correspondientes** | **Creación del Dex & Filtros** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Empezando

### Requisitos previos
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (se recomienda la versión estable más reciente)
* Dart SDK
* Un IDE como VS Code o Android Studio

### Instalación
1. Clona el repositorio:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Navega al directorio del proyecto:
   ```bash
   cd pokevault
   ```

3. Obtén las dependencias:
   ```bash
   flutter pub get
   ```

4. Descargar datos externos e inicializar submódulos:
   Obtener los últimos repositorios de datos y wikis utilizados por el generador de bases de datos:
   ```bash
   python3 update_data.py
   ```

5. Configurar Base de Datos SQLite:
   *PokéVault depende de una base de datos SQLite preconstruida para los datos principales de referencia de Pokémon.* 
   Ejecuta el script de la canalización de datos todo en uno para generar y optimizar `assets/db/pokedex.sqlite`:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Alternativamente, ejecuta con `--skip-download` si ya tienes los volúmenes web externos y solo deseas recompilar la base de datos).*

6. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## 🛠️ Construyendo la aplicación

Para compilar una versión de lanzamiento para su plataforma específica, ejecute uno de los siguientes comandos:

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

**Imagen de aplicación de Linux:**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**Web:**
```bash
flutter build web --release
```

## 📚 Arquitectura y documentación
* [Guía de arquitectura (`ARCHITECTURE.md`)](ARCHITECTURE.es.md): descripción general completa del sistema, arquitectura de estado (Proveedor), modelo de persistencia DAO, coordinador de sincronización de Google Drive, puente de traducción Isolate y puertas de calidad.
* [Git Workflow & Release Pipeline (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.es.md): modelo oficial de bifurcación de Git, reglas de protección de bifurcaciones, compilaciones multiplataforma (Android APK, Windows Zip, Linux AppImage/tar.gz) y prelanzamientos beta automatizados.
* [hoja de ruta v1.7.0: la expansión del lenguaje (`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md): especificación técnica completa para idiomas separados, API REST local, seguimiento de múltiples emuladores, OCR de escritorio y escáner de cámara móvil.
* [Canalización del generador de bases de datos (`tool/data_pipeline/README.md`)](../tool/data_pipeline/locales/README.es.md): documentación detallada para desarrolladores sobre análisis de PokeAPI fuera de línea, raspadores web, datos legales de Pokéball, índices y pasos de compilación de bases de datos.
* [Herramientas de desarrollo y lanzamiento (`tool/README.md`)](../tool/locales/README.es.md): documentación para el cambio automático de versiones de lanzamiento (`bump_version.py`), pruebas unitarias, cobertura de código y proceso de traducción automática (`translate_all.py`).

## 🤝 Contribuyendo con datos (correcciones de la comunidad)
¿Faltan encuentros o tienes mejores sugerencias de Matching Ball? Puede agregar o corregir fácilmente estos datos en los archivos JSON ubicados en el directorio `tool/data_pipeline/` (si corresponde) o contribuir directamente a través de Issues/Pull Requests.

Si desea contribuir con código, funciones o correcciones de errores, utilice las plantillas de problemas apropiadas en la carpeta `.github/ISSUE_TEMPLATE` y abra una solicitud de extracción en una rama de funciones dedicada.

## 🙏 Créditos y fuentes
Esta aplicación no sería posible sin estos increíbles recursos comunitarios:
* [PokeAPI](https://pokeapi.co/): datos base y obras de arte oficiales.
* [Living Dex Inspiración](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): Hojas de cálculo de Google de la comunidad.
* [Bolas coincidentes Guía](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): Hoja de Excel seleccionada por la comunidad para hacer coincidir Poké Balls.
* [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): Mecánica de tasa de captura.
* [Google Gemini](https://gemini.google.com): Asistencia de IA en codificación y refactorización.
* ¡Y muchos más!

## 📄 Licencia
Este proyecto tiene la licencia [Licencia pública general GNU v3.0 (GPL-3.0)](../LICENSE).

**Descargo de responsabilidad:** Pokémon y todos los nombres respectivos son marcas comerciales y © de Nintendo, Creatures Inc. y GAME FREAK inc. Este es un proyecto gratuito y no comercial para fanáticos y no está afiliado, respaldado ni respaldado por Nintendo de ninguna manera.
