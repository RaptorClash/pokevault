# PokéVault v1.7.0 Release Notes — "The Language Expansion"

**New Features**
* **Live Pokémon Scanner & Overlay Tracker (Desktop & Mobile):** Real-time OCR scanning for emulator windows, custom screen-snipped regions, and webcams/capture cards (offloaded to a native Windows C++ / WinRT worker with Z-order self-window masking). Includes dual-zone and multi-encounter recognition, an always-on-top floating HUD, a persistent dock with 1-click Pokédex catch sync, plus a Mobile Camera Scanner with custom scan zones, split-screen, and draggable Picture-in-Picture (PiP).
* **Shiny Hunt Auto-Counter:** Automatic encounter counting linked directly to Desktop or Mobile scanners across single or parallel multi-instance slots (`#1`, `#2`, …). Supports Wild Encounter, Soft Reset, Egg Hatch, and Screen-Transition (black/white screen) modes, custom trigger/reset patterns, live count logs with 1-tap Undo, automatic Shiny pause alerts, and optional Beta visual Shiny heuristics (Sparkle-Delay & HSV Color-Deviation).
* **Multi-Hunt Dashboard:** Track and control multiple Shiny Hunts side-by-side with per-hunt auto-counter rules, live slot assignment, paused-hunt filtering, and direct hunt creation.
* **The Multi-Language Core & 13 Supported Languages:** Decoupled UI language from Pokémon franchise language (e.g., German UI with English or Japanese Pokémon names), full UI localization across 13 languages, an expanded `pokedex.sqlite` covering 1,025+ Pokémon in 9 franchise languages, and an automated multi-engine translation pipeline (`tool/translate_all.py` & `tool/translate_release_notes.py`).
* **Interactive v1.7 Tutorials:** New platform-aware interactive guides and demo previews for the Desktop/Mobile Scanner, Multi-Hunt Dashboard, and Shiny Auto-Counter.

**Improvements & Bug Fixes**
* **Cleaned Documentation Structure:** All multi-lingual documentation moved into organized `locales/` subdirectories.
* **In-App Updater Enhancements:** Overhauled release notes viewer with native language detection and clean collapsible section support.
* **Database & Memory Performance:** Faster indexing, reduced memory overhead in PC box and list views, and non-blocking native capture/OCR pipelines.
* **UI Polish & Stability:** Improved responsive layouts across narrow mobile viewports and desktop setups, plus hardened persistence and lifecycle handling.

**Full Changelog**: https://github.com/RaptorClash/pokevault/compare/v1.6.1...v1.7.0
