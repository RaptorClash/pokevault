# 🛠️ PokéVault 開発者・メンテナンスツール

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | **[🇯🇵 日本語](README.ja.md)** | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

このディレクトリには、開発、テストカバレッジ、翻訳パイプライン、データパイプライン、リリース管理のための補助スクリプトと自動化が含まれています。

---

## 📌 ツールの概要

| スクリプト / ツール | 言語 | 説明 |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | `pubspec.yaml` と Git リリースのための自動バージョン＆ビルド管理 |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | `bump_version.py` のユニットテストスイート（SemVer検証、正規表現、CLIフラグ） |
| [`translate_all.py`](../translate_all.py) | Python 3 | UI文字列、スラングクラスおよびドキュメントのための完全自動マルチエンジン翻訳パイプライン |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | コードカバレッジ付きでテストを実行し、LCOVレポートを生成 |
| [`data_pipeline/`](../../data_pipeline/locales/README.ja.md) | Python 3 | `pokedex.sqlite` のためのスクレイパー、JSONインポートおよびSQLiteコンパイル |

---

## 🌐 自動翻訳パイプライン (`translate_all.py`)

スクリプト `translate_all.py` は、すべてのアプリ文字列（`lib/i18n/strings_*.i18n.json`）を同期して翻訳し、Dart 言語登録（`lib/i18n/language_registry.g.dart`）を生成し、Slang をコンパイルし、すべてのプロジェクト文書を専用の `locales/` サブフォルダに翻訳します。

### 主な機能:
* **無料のマルチエンジン カスケード**: 必須の API キーなしで Bing $\rightarrow$ Google $\rightarrow$ MyMemory を使用します。
* **オプションの DeepL サポート**: 環境変数 `DEEPL_API_KEY` が設定されている場合、DeepL が優先的に使用されます。
* **構文とプレースホルダーの保護**:スラング パラメータ (`{name}`、`{count}`)、ICU 複数構造 (`{count, plural, ...}`)、および改行 (`\n`) を誤変換から保護します。
* **アンチポイズニング付き MD5 ハッシュ キャッシュ**: 翻訳は永続的にキャッシュされた `tool/.translation_cache.json` に保存されます。 間違った同一の戻り値は有効なものとしてキャッシュされません。
* **リクエストのバッチ処理**: HTTP リクエストを最小限に抑え、レート制限 (HTTP 429) を回避するために、文字列を 30 個のブロックで結合します。
* **柔軟なソース言語と自動検出 (`--source-lang`)**: 英語またはドイツ語の README が最後に編集されたかどうかを自動的に検出 (`auto`)、またはソースの手動強制を許可します。 language.
* **マークダウン リンクとナビゲーションの書き換え**: `locales/` サブフォルダーとメイン ディレクトリ間のリンクを自動的に調整し、ドキュメントの先頭に言語バーを生成します。

### 重要なCLIコマンド:
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

### 翻訳パイプラインのテスト:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 リリースバンプツール（`bump_version.py`）

スクリプト `bump_version.py` は `pubspec.yaml` のバージョンを [セマンティックバージョニング (SemVer)](https://semver.org/) に従って読み取り、更新し、内部の Flutter ビルド番号 (`+<build>`) を自動的にインクリメントします。

### 1. ファイル変更なしでのプレビュー (`--dry-run`)
現在のバージョンを確認し、何が変更されるかを表示します:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*出力例:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. バージョンを上げる（ビルド番号自動 +1）
```bash
python tool/bump_version.py 1.6.0
```
*`pubspec.yaml` の `version: 1.5.0+6` を `version: 1.6.0+7` に更新しました。*

### 3. 特定のビルド番号を指定する (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*バージョンを明示的に `1.6.0+10` に設定します。*

### 4. 自動でGitコミットとGitタグを作成する（`--commit` & `--tag`）
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Bumpツールのテストを実行する
スクリプトのロジックは、独立したユニットテストスイートによって保証されています：
```bash
python tool/test_bump_version.py
```

---

## 📊 コードカバレッジ（`run_coverage.ps1`）

Windows/PowerShellでは、テストカバレッジは以下のように測定できます:
```powershell
.\tool\run_coverage.ps1
```
追加の評価のために `coverage/lcov.info` ファイルを生成します.
