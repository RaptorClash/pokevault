# PokéVault 데이터베이스 생성 파이프라인 (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | **[🇰🇷 한국어](README.ko.md)** | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

이 디렉토리에는 PokéVault용 SQLite 참조 데이터베이스 `assets/db/pokedex.sqlite`를 생성하고 최적화하기 위한 완전한 오프라인 데이터 파이프라인이 포함되어 있습니다.

---

## 1. 개요 및 목표

PokéVault는 **오프라인 우선(Offline-First)** 원칙으로 작동합니다. 모든 정적 프랜차이즈 데이터(포켓몬 기본 능력치, 대체 형태, 포획률, 리본, 기술 학습 세트, 등장 장소, 샤이니 잠금, 다국어 종 이름 및 적절한 볼)는 빌드 시점에 SQLite 데이터베이스에 미리 집계되어 앱과 함께 제공됩니다.

이로 인해 실행 시간 동안 느린 API 조회가 필요하지 않으며, 사용자는 인터넷 연결 없이 어디서나 앱을 사용할 수 있습니다.

---

## 2. 시스템 요구사항 & 설정

- **Python 3.10 이상**
- **Git** 서브모듈 지원 포함
- 필요한 Python 패키지 설치:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Git 서브모듈 초기화:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. 데이터 소스 및 디렉터리 구조

이 파이프라인은 여러 신뢰할 수 있는 출처의 데이터를 결합합니다:

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
 - 포켓몬 마스터 데이터, 기본 통계, 유형, 능력, 이동 학습 세트, 다국어 종 이름 및 진화에 대한 구조화된 JSON 파일을 제공합니다.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - 독일 이름, 밴드 및 캐릭터 설명('모든 밴드 목록', '캐릭터'), 성별 차이 및 반짝이는 포켓몬.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 - 모든 세대에 걸친 글로벌 리본 목록, 게임 내 거래 및 독 포켓몬(오프라인 HTML로 저장됨).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - Kanto에서 Paldea 및 Z-A.
5까지 에디션별 선물 및 거래의 자세한 목록입니다. **커뮤니티 스프레드시트(`Legal_Matching_Pokeballs.xlsx`)**:
 - 에디션별로 잡을 수 있는 모든 포켓몬과 일치하는 포켓볼 미학에 대한 자세한 매트릭스입니다.

---

## 4. 빠른 전체 실행(올인원 러너)

모든 스크립트를 올바른 순서로 전체 파이프라인을 한 번의 명령으로 실행하려면 `run_pipeline.py`를 사용하세요:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

이 러너는 자동으로 다음을 처리합니다:
1. `update_data.py` (외부 데이터 및 Git 서브모듈 업데이트)
2. `build_database.py` (`assets/db/pokedex.sqlite` 생성, 기본 데이터 포함)
3. `update_pokemon_languages.py` (모든 종에 대해 10개 프랜차이즈 언어 동기화)
4. `update_evolutions_db.py` (진화 트리 강화)
5. `update_cap_locks_and_trades.py` (캡, 코스프레 및 교환 잠금 적용)
6. `optimize_databases.py` (커버링 인덱스 생성, `ANALYZE`, `VACUUM`)

---

## 5. 수동 절차 (단계별)

개별 스크립트를 수동으로 실행해야 하는 경우:

### 1단계: 외부 원시 데이터 & 서브모듈 업데이트
```bash
python update_data.py
```
*현재 HTML 캐시를 다운로드하고, 최신 `Legal_Matching_Pokeballs.xlsx`를 가져오며 `api-data` 서브모듈을 최신 상태로 업데이트합니다.*

### 2단계: SQLite 메인 데이터베이스 구축
```bash
python tool/data_pipeline/build_database.py
```
*`assets/db/pokedex.sqlite`를 생성하고, 모든 1,025개 이상의 포켓몬과 250개 이상의 폼을 읽으며 500개 이상의 샤이니 락을 집계합니다.*

### 3단계: 다국어 포켓몬 이름 동기화
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*`lib/i18n/languages.json`에서 모든 프랜차이즈 언어를 동적으로 읽고, 누락된 열(`name_fr`, `name_ja` 등)을 `ALTER TABLE`로 추가하며, 오프라인 PokeAPI JSON에서 이름을 채웁니다.*

### 4단계: 개발 트리 강화
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*개발 트리, 분기 및 트리거를 계산합니다.*

### 5단계: 모자, 코스프레 & 교환 포켓몬 등록
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*모자 피카츄, 코스프레 형태 및 교환 포켓몬을 `assets/db/pokedex.sqlite`와 `database/pokedex.sqlite`에 등록합니다.*

### 단계 6: 인덱스 생성, 최적화 및 VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*커버링 인덱스를 생성하고, `ANALYZE`, `PRAGMA optimize;` 및 `VACUUM`을 실행합니다.*

---

## 6. `pokedex.sqlite`의 테이블 개요

| 테이블 | 설명 | 중요지수 |
|---|---|---|
| 포켓몬' | 10개의 프랜차이즈 언어 열(`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`)을 포함한 1,025개 이상의 모든 포켓몬에 대한 기본 데이터 | `기본 키(id)` |
| '양식' | 대체 형태, 메가, G-Max, 지역 | `idx_forms_poke (pokemon_id)` |
| `dex_orders` | 지역 포켓몬 주문 | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `특수_덱스` | 특수 덱스(예: Legendary, Ultra Beasts) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `포켓몬_이동` | 모든 버전의 공격 학습 세트 | `idx_pokemon_moves_poke (pokemon_id, 버전_그룹)` |
| `포켓몬_능력` | 기술 및 숨겨진 능력 | `idx_pokemon_abilities_poke (pokemon_id)` |
| '만남' | 위치 및 만남 유형 | `idx_encounters_poke (pokemon_id, 버전_그룹)` |
| '진화' | 완전한 개발 트리 | `기본 키(종_ID)` |
| '리본' | 모든 세대의 리본 | `기본 키(id)` |
| '마크' | 모든 에디션의 캐릭터 | `기본 키(id)` |
| `shiny_locks` | 모든 반짝이는 자물쇠(글로벌 및 에디션) | `기본 키(포켓몬_id, 양식_이름, 게임_버전)` |
| `legal_balls` | 포켓몬 및 에디션별 합법적 포켓볼 | `idx_legal_balls_poke(pokemon_id, gen)` |

---

## 7. 검증 및 품질 보증

파이프라인 실행 후에는 생성된 데이터베이스가 완전하고 오류가 없는지 확인해야 합니다:

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

## 8. 경로 및 개발 규칙

이 디렉토리의 모든 스크립트는 동적, 상대 경로 해석을 사용합니다:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- 절대 운영체제 경로를 하드코딩하지 마십시오.
- 임시 JSON 파일을 `assets/data/`에 두지 마십시오; 모든 정적 데이터는 직접 관계형 SQLite 데이터베이스 `assets/db/pokedex.sqlite`에 있어야 합니다.
