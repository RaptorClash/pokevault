# 🛠️ 포케볼트 개발자 및 유지보수 도구

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | **[🇰🇷 한국어](README.ko.md)** | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

이 디렉토리에는 개발, 테스트 커버리지, 번역 파이프라인, 데이터 파이프라인 및 릴리스 관리를 위한 보조 스크립트 및 자동화가 포함되어 있습니다.

---

## 📌 도구 개요

| 스크립트 / 도구 | 언어 | 설명 |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | `pubspec.yaml` 및 Git 릴리스를 위한 자동 버전 및 빌드 관리 |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | `bump_version.py`의 단위 테스트 스위트 (SemVer 검증, 정규식, CLI 플래그) |
| [`translate_all.py`](../translate_all.py) | Python 3 | UI 문자열, 슬랭 클래스 및 문서를 위한 완전 자동 다중 엔진 번역 파이프라인 |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | 코드 커버리지를 포함한 테스트 실행 및 LCOV 보고서 생성 |
| [`data_pipeline/`](../data_pipeline/locales/README.ko.md) | Python 3 | `pokedex.sqlite`를 위한 스크래퍼, JSON 가져오기 및 SQLite 컴파일

---

## 🌐 자동 번역 파이프라인 (`translate_all.py`)

`translate_all.py` 스크립트는 모든 앱 문자열(`lib/i18n/strings_*.i18n.json`)을 동기화하고 번역하며, Dart 언어 등록(`lib/i18n/language_registry.g.dart`)을 생성하고, Slang를 컴파일하며, 모든 프로젝트 문서를 전용 `locales/` 하위 폴더로 번역합니다.

### 주요 기능:
* **무료 다중 엔진 캐스케이드**: 필수 API 키 없이 Bing $\rightarrow$ Google $\rightarrow$ MyMemory를 사용합니다.
* **DeepL 지원 옵션**: 환경 변수 `DEEPL_API_KEY`가 설정된 경우 DeepL이 우선적으로 사용됩니다.
* **구문 및 자리 표시자 보호**: 속어 매개 변수를 보호합니다. (`{name}`, `{count}`), 잘못된 번역으로 인한 ICU 복수형 구조(`{count, plural, ...}`) 및 줄 바꿈(`\n`).
* **중독 방지 기능이 있는 MD5 해시 캐시**: 번역은 `tool/.translation_cache.json`에 지속적으로 캐시되어 저장됩니다. 부정확하고 동일한 반환은 유효한 것으로 캐시되지 않습니다.
* **요청 일괄 처리**: HTTP 요청을 최소화하고 속도 제한을 피하기 위해 문자열을 30개 블록으로 결합합니다(HTTP 429).
* **유연한 소스 언어 및 자동 감지(`--source-lang`)**: 영어 또는 독일어 README가 마지막으로 편집되었는지 자동으로 감지(`auto`)하거나 소스의 수동 강제 적용을 허용합니다. 언어.
* **마크다운 링크 및 탐색 재작성**: `locales/` 하위 폴더와 기본 디렉터리 간의 링크를 자동으로 조정하고 문서 헤드에 입력 도구 모음을 생성합니다.

### 중요한 CLI 명령어:
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

### 번역 파이프라인 테스트:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 릴리스 버전 올리기 도구 (`bump_version.py`)

`bump_version.py` 스크립트는 `pubspec.yaml`에서 버전을 읽고 [Semantic Versioning (SemVer)](https://semver.org/)에 따라 업데이트하며 내부 Flutter 빌드 번호(`+<build>`)를 자동으로 증가시킵니다.

### 1. 파일 변경 없이 미리보기(`--dry-run`)
현재 버전을 확인하고, 무엇이 변경될 것인지 표시합니다:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*출력 예시:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. 버전 올리기 (빌드 번호 자동 +1)
```bash
python tool/bump_version.py 1.6.0
```
*`pubspec.yaml`에서 `version: 1.5.0+6` $
ightarrow$ `version: 1.6.0+7`로 업데이트했습니다.*

### 3. 특정 빌드 번호 지정 (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*버전을 명시적으로 `1.6.0+10`으로 설정합니다.*

### 4. 자동으로 Git 커밋 및 Git 태그 생성 (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Bump 도구에 대한 테스트 실행
스크립트의 로직은 독립적인 단위 테스트 스위트로 안전하게 보호됩니다:
```bash
python tool/test_bump_version.py
```

---

## 📊 코드 커버리지 (`run_coverage.ps1`)

Windows/PowerShell에서 테스트 커버리지는 다음과 같이 측정할 수 있습니다:
```powershell
.\tool\run_coverage.ps1
```
추가 분석을 위해 `coverage/lcov.info` 파일을 생성합니다.
