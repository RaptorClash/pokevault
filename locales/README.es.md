# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | **[🇪🇸 Español](README.es.md)** | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** es un acompañante completo y totalmente personalizable para entrenadores de Pokémon, coleccionistas y cazadores de Shiny, desarrollado con Flutter. No importa si planeas un Dex regional, un Dex nacional, un Dex de formas o un Dex Shiny: PokéVault te ayuda a mantener un seguimiento fácil de tu progreso y te proporciona las herramientas necesarias para tu caza de Shiny.

[![CI Quality Gate](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml/badge.svg)](https://github.com/RaptorClash/pokevault/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-lightgrey)
![Lizenz](https://img.shields.io/badge/Lizenz-GPL--3.0-blue.svg)

## ✨ Funciones principales

* **Gestión Multi-Dex:** Crea tantos rastreadores como quieras para diferentes juegos, generaciones o tus propios desafíos.
* **Seguimiento de formulario detallado:** Soporte completo para formas regionales, megaevoluciones, Gigantamax y formas especiales (Pokusan, Vivillon, Unown, etc.).
* **Caja de PC y vista de lista:** Visualiza tus Pokémon en la cuadrícula clásica "PC Box" de 30 espacios o en una lista con capacidad de búsqueda sin interrupciones arrastrar y soltar.
* **Seguimiento brillante y contador de caza:** Rastrea Pokémon normales y brillantes por separado. Contador Shiny Hunt incorporado con cálculo de probabilidad en tiempo real, selección de método, historial de fases y temporizador de sesión con detección de pausa AFK.
* **🎖️ Tarjetas de finalización Dex:** Diseña, personaliza y exporta certificados de logros de alta resolución, tarjetas de estadísticas y mosaicos de Pokémon para compartir tu progreso.
* **Bolas a juego:** Recibe recomendaciones seleccionadas por la comunidad para las mejores Poké Balls (para las normales *y* brillantes variantes)!
* **📊 Calculadora de tasa de captura avanzada:** Cálculo preciso de la probabilidad de captura en todas las generaciones, incluidas mecánicas especiales de *Pokémon Legends: Arceus* y *Pokémon Legends: Z-A*.
* **🧬 Calculadora de ruta y reproducción brillante:** Calcula cadenas de reproducción de varias etapas (incluidos Ditto y Pokémon bebés) y muestra las probabilidades exactas para el objetivo offspring.
* **📖 Guías detalladas de caza brillante:** Instrucciones paso a paso para métodos específicos de cada generación (por ejemplo, PokéRadar, DexNav, recetas de sándwiches).
* **🎮 Descripción general de atajos y operaciones en la aplicación:** Pantalla propia en la configuración con atajos adaptables a la plataforma, comandos del mouse y gestos táctiles.
* **☁️ Sincronización en la nube y Primero sin conexión:** 100 % compatible sin conexión con una sólida base de datos SQLite local. Sincronización opcional a través de su Google Drive privado con resiliencia de combinación de parches.
* **Personalización completa:** Admite modo oscuro/claro y acento y colores de fondo personalizables.
* **Multilingüe:** Totalmente disponible en 13 idiomas (UI a través de Slang). Además, selección independiente del idioma de la franquicia Pokémon (por ejemplo, interfaz de usuario en alemán con nombres de Pokémon en inglés o japonés) basada en 10 idiomas oficiales de la franquicia en `pokedex.sqlite`.

## 📸 Capturas de pantalla

| Pantalla de Inicio | Vista de Caja de PC |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Detalles de Pokémon y Bolas Correspondientes** | **Creación de Dex y Filtros** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Primeros pasos (Ejecutar localmente)

### Requisitos
* [SDK de Flutter](https://docs.flutter.dev/get-started/install) (se recomienda la versión estable actual)
* SDK de Dart
* Un IDE como VS Code o Android Studio

### Instalación
1. Clonar el repositorio:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Cambiar al directorio:
   ```bash
   cd pokevault
   ```

3. Descargar dependencias:
   ```bash
   flutter pub get
   ```

4. Descargar datos externos e inicializar submódulos:
   Descarga los repositorios de datos y wikis más recientes necesarios para la base de datos:
   ```bash
   python3 update_data.py
   ```

5. Generar y optimizar la base de datos SQLite:
   *PokéVault requiere una base de datos SQLite precompilada para los datos básicos de Pokémon.* 
   Ejecuta el script de pipeline todo-en-uno para generar y optimizar `assets/db/pokedex.sqlite` con un solo comando:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Alternativamente, ejecútalo con `--skip-download` si ya tienes los volúmenes web externos y solo deseas reconstruir la base de datos).*

6. Iniciar la aplicación:
   ```bash
   flutter run
   ```

## 🛠️ Crear compilación

Para crear una compilación de lanzamiento, utiliza uno de los siguientes comandos:

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

**Web:**
```bash
flutter build web --release
```

## 📚 Arquitectura y documentación
* [Guía de arquitectura (`ARCHITECTURE.md`)](../../ARCHITECTURE.md): descripción detallada de la arquitectura del sistema, gestión del estado del proveedor, modelo de persistencia DAO, coordinador de sincronización de Google Drive, puente de traducción aislado y puertas de calidad de prueba.
* [ramificación de Git y canalización de lanzamiento (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../../docs/GIT_WORKFLOW_AND_RELEASES.md): modelo de bifurcación oficial de Git, reglas de protección de bifurcaciones, compilaciones multiplataforma (Android APK, Windows Zip, Linux AppImage/tar.gz) y versiones preliminares de Beta automatizadas.
* [v1.7.0 Hoja de ruta: la expansión del lenguaje (`docs/plans/v1_7_0_the_language_expansion.md`)](../../docs/plans/v1_7_0_the_language_expansion.md): especificación técnica completa para idiomas separados, servidor REST local, seguimiento de múltiples emuladores, OCR de escritorio y escáner de cámara móvil.
* [Canal de generación de base de datos (`tool/data_pipeline/locales/README.de.md`)](../../tool/data_pipeline/locales/README.es.md): documentación de preparación de datos PokeAPI fuera de línea, raspadores, importación de bolas coincidentes, índices y compilación de bases de datos.
* [Herramientas de desarrollo y lanzamiento (`tool/locales/README.de.md`)](../../tool/locales/README.es.md): gestión automatizada de versiones de lanzamiento (`bump_version.py`), conjuntos de pruebas, cobertura de código y proceso de traducción (`translate_all.py`).

## 🤝 Complementar datos (Contribuciones de la comunidad)
¿Te faltan ubicaciones o las pelotas coincidentes no encajan? Puedes completar estos datos en los archivos JSON en el directorio `tool/data_pipeline/` (si existen) o contribuir directamente a través de Issues/Pull Requests.

Si deseas contribuir con código, funciones o correcciones de errores, utiliza las plantillas de problemas correspondientes en la carpeta `.github/ISSUE_TEMPLATE` y abre un Pull Request en una rama de funciones propia.

## 🙏 Agradecimientos y Fuentes
Esta aplicación no habría sido posible sin estos increíbles recursos de la comunidad:
*   [PokeAPI](https://pokeapi.co/): Datos básicos y artes oficiales.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): Hojas de cálculo de Google de la comunidad como base de seguimiento.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): Tabla de Excel curada por la comunidad para las Pokébolas perfectas.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): Mecánicas de tasa de captura.
*   [Google Gemini](https://gemini.google.com): Asistencia de IA para programar y refactorizar.
* ¡Y muchos más!

## 📄 Licencia
Este proyecto está licenciado bajo la [Licencia Pública General de GNU v3.0 (GPL-3.0)](../LICENSE).

**Descargo de responsabilidad:** Pokémon y todos los nombres asociados son marcas registradas y © de Nintendo, Creatures Inc., y GAME FREAK inc. Este es un proyecto de fans gratuito y no comercial, y no tiene ninguna relación con Nintendo ni está apoyado o patrocinado por ellos.
