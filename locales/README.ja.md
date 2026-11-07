# 🔴 ポケヴォルト

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | **[🇯🇵 日本語](README.ja.md)** | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault**は、Flutterで開発された、ポケモントレーナー、コレクター、そして色違いポケモンハンター向けの包括的で完全にカスタマイズ可能なアシスタントです。地域別図鑑、全国図鑑、フォーム図鑑、色違い図鑑のどれを計画していても、PokéVaultはあなたの進捗状況を簡単に管理できるようにサポートし、色違い狩りに必要なツールを提供します。

__バッジ_ブロック_0__
__バッジ_ブロック_1__
__バッジ_ブロック_2__
__バッジ_ブロック_3__
__バッジ_ブロック_4__

## ✨ 主な機能

* **マルチデックス管理:** さまざまなゲーム、世代、または独自の課題に合わせて必要な数のトラッカーを作成します。
* **詳細なフォーム追跡:** 地域フォーム、メガ進化、キョダイマックス、特別なフォーム (ポクサン、ビビヨン、アンノーンなど) を完全にサポート。
* **PC ボックス & リスト ビュー:** クラシックな 30 スロットの「PC ボックス」グリッドまたはシームレスなドラッグ アンド ドロップで検索可能なリスト。
* **シャイニー トラッキング & ハント カウンター:** 通常のポケモンとシャイニー ポケモンを別々に追跡します。 リアルタイムの確率計算、メソッド選択、フェーズ履歴、AFK 一時停止検出機能を備えた内蔵シャイニー ハント カウンター。
* **🎖️ Dex コンプリーション カード:** 高解像度の達成証明書、ステータス カード、ポケモン モザイクをデザイン、カスタマイズ、エクスポートして、進捗状況を共有します。
* **マッチング ボール:** コミュニティが厳選した最高のポケの推奨事項を受け取ります。ボール (通常の * および * 光沢のあるバリアント用)!
* **📊 高度な捕獲率計算機:** *ポケモンレジェンド: アルセウス* および *ポケモンレジェンド: Z-A* の特別な仕組みを含む、全世代にわたる捕獲確率の正確な計算。
* **🧬 光沢のある繁殖とルート計算機:** 多段階の繁殖連鎖を計算
* **📖 詳細な光沢のある狩猟ガイド:** 世代固有の方法 (例: ポケレーダー、DexNav、サンドイッチのレシピ) のステップバイステップの説明。 
* **🎮 アプリ内操作とショートカットの概要:** プラットフォームに適応したショートカット、マウス コマンドを使用した設定の独自画面
* **☁️ クラウド同期とオフラインファースト:** 堅牢なローカル SQLite データベースにより 100% オフライン対応。 オプションで、パッチ マージの復元力を備えたプライベート Google ドライブ経由で同期できます。
* **完全なパーソナライゼーション:** ダーク/ライト モードとカスタマイズ可能なアクセント カラーと背景色をサポートします。
* **多言語:** 13 か国語で完全に利用可能 (Slang 経由の UI)。 さらに、「pokedex.sqlite」内の 10 の公式フランチャイズ言語に基づいて、ポケモン フランチャイズ言語 (例: 英語または日本語のポケモン名を持つドイツ語の UI) が独立して選択されます。

## 📸 スクリーンショット

| ホーム画面 | PCボックス表示 |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **ポケモンの詳細 & マッチングボール** | **図鑑作成 & フィルター** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 初めに (ローカルで実行)

### 前提条件
* [Flutter SDK](https://docs.flutter.dev/get-started/install)（最新の安定版を推奨）
* Dart SDK
* VS Code や Android Studio のような IDE

### インストール
1. リポジトリをクローンする:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. ディレクトリに移動する:
   ```bash
   cd pokevault
   ```

3. 依存関係をダウンロードする:
   ```bash
   flutter pub get
   ```

4. 外部データのダウンロードとサブモジュールの初期化:
   データベースに必要な最新のデータリポジトリとウィキをダウンロードします:
   ```bash
   python3 update_data.py
   ```

5. SQLiteデータベースの生成と最適化:
   *PokéVaultはポケモンの基本データ用に事前コンパイルされたSQLiteデータベースを必要とします。* 
   オールインワンのパイプラインスクリプトを実行して、`assets/db/pokedex.sqlite` を1つのコマンドで生成および最適化します:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(外部Webダンプをすでに持っていてデータベースだけ再構築したい場合は、`--skip-download` を使用して実行できます。)*

6. アプリを起動:
   ```bash
   flutter run
   ```

## 🛠️ ビルドを作成

リリースビルドを作成するには、次のいずれかのコマンドを使用してください:

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

**ウェブ:**
```bash
flutter build web --release
```

## 📚 アーキテクチャとドキュメント
* [アーキテクチャ ガイド (`ARCHITECTURE.md`)](../../ARCHITECTURE.md): システム アーキテクチャ、プロバイダーの状態管理、DAO 永続モデル、Google ドライブ同期コーディネーター、翻訳ブリッジの分離、およびテスト品質ゲートの詳細な概要。
* [Git ブランチとリリース パイプライン(`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../../docs/GIT_WORKFLOW_AND_RELEASES.md): 公式 Git ブランチング モデル、ブランチ保護ルール、マルチプラットフォーム ビルド (Android APK、Windows Zip、Linux AppImage/tar.gz) および自動ベータ プレリリース。
* [v1.7.0 ロードマップ: 言語拡張(`docs/plans/v1_7_0_the_ language_expansion.md`)](../../docs/plans/v1_7_0_the_ language_expansion.md): 分離言語、ローカル REST サーバー、マルチエミュレータ トラッキング、デスクトップ OCR およびモバイル カメラ スキャナーの完全な技術仕様。
* [データベース生成パイプライン] (`tool/data_pipeline/locales/README.de.md`)](../tool/data_pipeline/locales/README.de.md): オフライン PokeAPI データの準備、スクレイパー、マッチング ボールのインポート、インデックス、データベースのコンパイルに関するドキュメント。
* [開発者およびリリース ツール] (`tool/locales/README.de.md`)](../tool/locales/README.de.md): 自動リリース バージョン管理 (`bump_version.py`)、テスト スイート、コード カバレッジ、および変換パイプライン (`translate_all.py`)。

## 🤝 データを補完する（コミュニティ貢献）
場所が足りない、またはマッチングボールが合わない場合は、`tool/data_pipeline/` ディレクトリ内の JSON ファイル（存在する場合）にこれらのデータを補完するか、直接 Issues/Pull Requests を通じて貢献できます。

コード、機能、またはバグ修正を提供したい場合は、`.github/ISSUE_TEMPLATE` フォルダ内の対応する Issue テンプレートを使用し、自分の機能ブランチでプルリクエストを開いてください。

## 🙏 謝辞と情報源
このアプリは、コミュニティの素晴らしいリソースがなければ実現できませんでした：
*   [PokeAPI](https://pokeapi.co/): 基本データと公式アートワーク。
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): コミュニティのGoogleスプレッドシートをトラッカーベースとして使用。
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): 完璧なポケモンボールのためのコミュニティキュレーションされたExcel表。
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): 捕獲率の仕組み。
*   [Google Gemini](https://gemini.google.com): プログラミングとリファクタリングでのAIアシスタント。
* そしてその他多数!

## 📄 ライセンス
このプロジェクトは [GNU 一般公衆利用許諾契約書 v3.0 (GPL-3.0)](../LICENSE) の下でライセンスされています。

**免責事項:** ポケモンおよび関連するすべての名前は、任天堂、クリーチャーズ株式会社、ゲームフリーク株式会社の商標および©です。これは無料の非商業的ファンプロジェクトであり、任天堂とは一切関係がなく、任天堂によってサポートもスポンサーもされていません。
