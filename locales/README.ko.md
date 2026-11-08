# 🔴 포켓볼트

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | **[🇰🇷 한국어](README.ko.md)** | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault**은 Flutter로 개발된 포켓몬 트레이너, 수집가 및 샤이니 헌터를 위한 포괄적이고 완전히 사용자 정의 가능한 동반자 앱입니다. 지역 도감, 전국 도감, 형태 도감 또는 샤이니 도감을 계획하든 상관없이, PokéVault는 진행 상황을 쉽게 확인할 수 있도록 도와주며 샤이니 수집을 위한 필요한 도구를 제공합니다.

__배지_블록_0__
__배지_블록_1__
__배지_블록_2__
__배지_블록_3__
__배지_블록_4__

## ✨ 주요 기능

* **Multi-Dex 관리:** 다양한 게임, 세대 또는 자신의 과제에 대해 원하는 만큼 추적기를 생성합니다.
* **세부 양식 추적:** 지역 양식, 메가 진화, Gigantamax 및 특수 형태(Pokusan, Vivillon, Unown 등)를 완벽하게 지원합니다.
* **PC 상자 및 목록 보기:** 클래식 30 슬롯 "PC 상자" 그리드 또는 원활한 드래그 및 검색 가능한 목록에서 포켓몬을 봅니다. drop.
* **샤이니 추적 및 사냥 카운터:** 일반 포켓몬과 샤이니 포켓몬을 별도로 추적합니다. 실시간 확률 계산, 방법 선택, 단계 기록 및 AFK 일시 중지 감지 기능이 있는 세션 타이머가 내장된 Shiny Hunt 카운터.
* **🎖️ Dex 완료 카드:** 고해상도 성취 인증서, 통계 카드 및 포켓몬 모자이크를 디자인하고 개인화하고 내보내 진행 상황을 공유합니다.
* **짝 짝 맞추기:** 최고의 포켓볼에 대한 커뮤니티 선별 추천 받기(일반 *및* 반짝임에 대해) 변형)!
* **📊 고급 포획률 계산기:** *Pokémon Legends: Arceus* 및 *Pokémon Legends: Z-A*의 특수 메커니즘을 포함하여 모든 세대에 걸친 포획 확률의 정확한 계산.
* **🧬 빛나는 번식 및 경로 계산기:** 다단계 번식 체인(Ditto 및 아기 포켓몬 포함)을 계산하고 대상에 대한 정확한 확률을 표시합니다. offspring.
* **📖 자세한 반짝이는 헌팅 가이드:** 세대별 방법에 대한 단계별 지침(예: PokéRadar, DexNav, 샌드위치 레시피).
* **🎮 앱 내 작동 및 단축키 개요:** 플랫폼 적응형 단축키, 마우스 명령 및 터치 제스처가 포함된 설정에서 자체 화면.
* **☁️ 클라우드 동기화 및 오프라인 우선:** 강력한 로컬 SQLite 데이터베이스로 100% 오프라인이 가능합니다. 패치 병합 복원력을 갖춘 개인 Google 드라이브를 통한 선택적 동기화.
* **완전한 개인화:** 어두운/밝은 모드와 사용자 정의 가능한 악센트 및 배경 색상을 지원합니다.
* **다국어:** 13개 언어로 완전히 사용 가능합니다. (속어를 통한 UI) 또한 `pokedex.sqlite`의 10개 공식 프랜차이즈 언어를 기반으로 포켓몬 프랜차이즈 언어(예: 영어 또는 일본어 포켓몬 이름이 포함된 독일어 UI)를 독립적으로 선택합니다.

## 📸 스크린샷

| 홈 화면 | PC 박스 보기 |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **포켓몬 상세 정보 & 매칭 볼** | **덱스 생성 & 필터** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 첫 단계 (로컬에서 실행)

### 전제 조건
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (권장: 최신 안정 버전)
* Dart SDK
* VS Code 또는 Android Studio와 같은 IDE

### 설치
1. 리포지토리 클론:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. 디렉토리로 이동:
   ```bash
   cd pokevault
   ```

3. 종속 항목 다운로드:
   ```bash
   flutter pub get
   ```

4. 외부 데이터 다운로드 및 서브모듈 초기화:
   데이터베이스에 필요한 최신 데이터 리포지토리와 위키를 다운로드하세요:
   ```bash
   python3 update_data.py
   ```

5. SQLite 데이터베이스 생성 및 최적화:
   *PokéVault는 포켓몬 기본 데이터를 위한 미리 컴파일된 SQLite 데이터베이스가 필요합니다.* 
   All-in-One 파이프라인 스크립트를 실행하여 `assets/db/pokedex.sqlite`를 한 번의 명령으로 생성하고 최적화하세요:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(이미 외부 웹 덤프를 가지고 있고 데이터베이스만 다시 만들고 싶은 경우 `--skip-download` 옵션으로 실행할 수 있습니다).*

6. 앱 시작:
   ```bash
   flutter run
   ```

## 🛠️ 빌드 생성

릴리스 빌드를 만들기 위해 다음 명령어 중 하나를 사용하십시오:

**안드로이드 (APK):**
```bash
flutter build apk --release
```

**윈도우:**
```bash
flutter build windows --release
```

**리눅스:**
```bash
flutter build linux --release
```

**리눅스 AppImage:**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**웹:**
```bash
flutter build web --release
```

## 📚 아키텍처 및 문서
* [아키텍처 가이드(`ARCHITECTURE.md`)](ARCHITECTURE.ko.md): 시스템 아키텍처, 공급자 상태 관리, DAO 지속성 모델, Google 드라이브 동기화 코디네이터, 번역 브리지 격리 및 품질 게이트 테스트에 대한 자세한 개요.
* [Git 분기 및 릴리스 파이프라인 (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.ko.md): 공식 Git 분기 모델, 분기 보호 규칙, 다중 플랫폼 빌드(Android APK, Windows Zip, Linux AppImage/tar.gz) 및 자동화된 베타 사전 릴리스.
* [v1.7.0 로드맵: 언어 확장 (`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md): 분리된 언어, 로컬 REST 서버, 다중 에뮬레이터 추적, 데스크톱 OCR 및 모바일 카메라 스캐너에 대한 전체 기술 사양입니다.
* [데이터베이스 생성 파이프라인 (`tool/data_pipeline/locales/README.de.md`)](../tool/data_pipeline/locales/README.ko.md): 오프라인 PokeAPI 데이터 준비, 스크레이퍼, 매칭 볼 가져오기, 인덱스 및 데이터베이스 컴파일에 대한 문서입니다.
* [개발자 및 릴리스 도구(`tool/locales/README.de.md`)](../tool/locales/README.ko.md): 자동화된 릴리스 버전 관리(`bump_version.py`), 테스트 스위트, 코드 적용 범위 및 번역 파이프라인(`translate_all.py`).

## 🤝 데이터 추가 (커뮤니티 기여)
발견 위치가 부족하거나 매칭 볼이 맞지 않나요? 이 데이터를 `tool/data_pipeline/` 디렉터리의 JSON 파일에 추가할 수 있습니다(있는 경우) 또는 직접 이슈/풀 리퀘스트를 통해 기여할 수 있습니다.

코드, 기능 또는 버그 수정을 기여하고 싶다면, `.github/ISSUE_TEMPLATE` 폴더에 있는 해당 이슈 템플릿을 사용하고, 자신의 기능 브랜치에서 풀 리퀘스트를 열어주세요.

## 🙏 감사 및 출처
이 앱은 커뮤니티의 훌륭한 자원 없이는 불가능했을 것입니다:
*   [PokeAPI](https://pokeapi.co/): 기본 데이터 및 공식 아트워크.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): 트래커 기반으로 사용된 커뮤니티 구글 시트.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): 완벽한 포켓볼을 위한 커뮤니티 큐레이션 엑셀 시트.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): 캡처율 메커니즘.
*   [Google Gemini](https://gemini.google.com): 프로그래밍 및 리팩토링 시 AI 지원.
* 그리고 그 외 여러 자료!

## 📄 라이선스
이 프로젝트는 [GNU 일반 공중 사용 허가서 v3.0 (GPL-3.0)](../LICENSE)에 따라 라이선스가 부여됩니다.

**면책 조항:** 포켓몬과 모든 관련 이름은 Nintendo, Creatures Inc., 및 GAME FREAK inc.의 상표 및 ©입니다. 이것은 무료 비상업적 팬 프로젝트이며 Nintendo와 어떠한 관련도 없으며 Nintendo로부터 지원이나 후원을 받지 않습니다.
