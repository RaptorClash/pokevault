# PokéVault v1.7.0 Release Notes — "The Language Expansion"

**New Features**
* **The Multi-Language Core:** Decoupled UI language from Pokémon franchise language. You can now use a German UI with English or Japanese Pokémon names!
* **13 Supported Languages:** Full UI localization available in German, English, French, Spanish, Italian, Japanese, Korean, Simplified Chinese, Traditional Chinese, Portuguese, Dutch, Polish, and Russian.
* **Expanded Database (pokedex.sqlite):** Includes localized names for all 1,025+ Pokémon across 9 official franchise languages.
* **Automated Translation Pipeline:** Full CLI tooling (`tool/translate_all.py` & `tool/translate_release_notes.py`) with multi-engine fallback and placeholder protection.

**Improvements & Bug Fixes**
* **Cleaned Documentation Structure:** All multi-lingual documentation moved into organized `locales/` subdirectories.
* **In-App Updater Enhancements:** Overhauled release notes viewer with native language detection and clean collapsible section support.
* **Database & Memory Performance:** Faster indexing and reduced memory overhead in PC box and list views.
* General stability and performance improvements.

**Full Changelog**: https://github.com/RaptorClash/pokevault/compare/v1.6.1...v1.7.0
