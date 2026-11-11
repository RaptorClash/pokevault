# PokéVault データベース生成パイプライン（`tool/data_pipeline/`）

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | **[🇯🇵 日本語](README.ja.md)** | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

このディレクトリには、PokéVault 用の SQLite リファレンスデータベース `assets/db/pokedex.sqlite` を作成および最適化するための完全なオフラインデータパイプラインが含まれています。

---

## 1. 概要と目的

PokéVaultは**オフラインファースト**の原則に基づいて動作します。すべての静的なフランチャイズデータ（ポケモンの基本ステータス、代替フォーム、捕獲率、リボン、技の習得セット、出現場所、色違いロック、多言語の種族名および対応するボール）は、ビルド時にSQLiteデータベースに事前集計され、アプリと共に配信されます。

これにより、実行時の遅いAPIクエリが不要になり、ユーザーはインターネット接続なしでどこでもアプリを使用できます。

---

## 2. システム要件とセットアップ

- **Python 3.10以上**
- **サブモジュール対応のGit**
- 必要なPythonパッケージをインストールする:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Gitサブモジュールを初期化する:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. データソースとディレクトリ構造

このパイプラインは、複数の信頼できるソースからのデータを統合します：

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
 - ポケモンのマスター データ、基本ステータス、タイプ、能力、技学習セット、多言語の種名と進化の構造化された JSON ファイルを提供します。
2。 **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - ドイツ語の名前、バンドとキャラクターの説明 (「すべてのバンドのリスト」、「キャラクター」)、性別の違い、光沢のあるポケモン。
3。 **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 - 全世代にわたるグローバル リボン リスト、ゲーム内トレード、どくポケモン (オフライン HTML として保存)。
4。 **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - カントーからパルデアおよび Z-A までのエディション固有のギフトとトレードの詳細なリスト。
5。 **コミュニティ スプレッドシート (`Legal_Matching_Pokeballs.xlsx`)**:
 - エディションごとの捕まえられるすべてのポケモンと一致するモンスターボールの美学の詳細なマトリックス。

---

## 4. 高速全体実行（オールインワンランナー）

すべてのスクリプトを正しい順序で単一のコマンドで実行するには、`run_pipeline.py` を使用してください:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

このランナーは自動的に次のことを行います:
1. `update_data.py`（外部データおよびGitサブモジュールを更新）
2. `build_database.py`（基礎データで `assets/db/pokedex.sqlite` を生成）
3. `update_pokemon_languages.py`（すべての種に対して10のフランチャイズ言語を同期）
4. `update_evolutions_db.py`（進化ツリーを充実させる）
5. `update_cap_locks_and_trades.py`（キャップ、コスプレ、トレード制限を登録）
6. `optimize_databases.py`（カバリングインデックス作成、`ANALYZE`、`VACUUM`）

---

## 5. 手動手順（個別ステップ）

個別のスクリプトを手動で実行する場合:

### ステップ 1: 外部の生データとサブモジュールを更新
```bash
python update_data.py
```
*最新のHTMLキャッシュをダウンロードし、最新の `Legal_Matching_Pokeballs.xlsx` を取得し、`api-data` サブモジュールを最新の状態にします。*

### ステップ2: SQLiteメインデータベースを構築
```bash
python tool/data_pipeline/build_database.py
```
*`assets/db/pokedex.sqlite`を作成し、1,025以上のポケモンと250以上のフォルムをすべて読み込み、500以上のシャイニー・ロックを集計します.*

### ステップ3: 多言語のポケモン名を同期する
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*すべてのフランチャイズ言語を `lib/i18n/languages.json` から動的に読み込み、欠けているカラム（`name_fr`、`name_ja` など）を `ALTER TABLE` で追加し、オフラインの PokeAPI JSON から名前を入力します。*

### ステップ4：開発ツリーを強化する
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*開発ツリー、分岐、およびトリガーを計算します。*

### ステップ5: キャップ、コスプレ、トレードポケモンを追加
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*キャップピカチュウ、コスプレフォーム、トレードポケモンを `assets/db/pokedex.sqlite` と `database/pokedex.sqlite` に追加します。*

### ステップ6: インデックスの作成、最適化 & VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*カバリングインデックスを作成し、`ANALYZE`、`PRAGMA optimize;`、および `VACUUM` を実行します。*

---

## 6. `pokedex.sqlite` のテーブル概要

|表 |説明 |重要なインデックス |
|---|---|---|
|ポケモン10 のフランチャイズ言語列 (`name_de`、`name_en`、`name_fr`、`name_es`、`name_it`、`name_ja`、`name_ko`、`name_zh_hans`、`name_zh_hant`) を含む 1,025 匹以上のポケモンすべての基本データ。 `主キー (id)` |
| `フォーム` |代替フォーム、メガ、G-Max、地域 | `idx_forms_poke (pokemon_id)` |
| `dex_orders` |地域のポケモン図鑑の注文 | `idx_dex_orders_poke_dex (ポケモン ID、dex_name、order_index)` |
| `special_dexes` |特別な能力 (例: 伝説のビースト、ウルトラビースト) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `ポケモンの動き` |全バージョンの攻撃学習セット | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `ポケモンの能力` |スキルと隠れた能力 | `idx_pokemon_abilities_poke (pokemon_id)` |
| 「出会い」 |場所と遭遇タイプ | `idx_encounters_poke (pokemon_id, version_group)` |
| 「進化」 |完全な開発ツリー | `主キー (種_id)` |
|リボンあらゆる世代のリボン | `主キー (id)` |
| `マーク' |全エディションのキャラクター | `主キー (id)` |
| `shiny_locks` |すべての Shiny Locks (グローバルおよびエディション) | `PRIMARY KEY (pokemon_id, form_name, game_version)` |
| `リーガルボール` |ポケモンとエディションごとの合法的なモンスター ボール | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. 検証と品質保証

パイプラインの各実行後に、生成されたデータベースが完全でエラーがないことを確認する必要があります。

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

## 8. パスおよび開発規約

このディレクトリ内のすべてのスクリプトは動的で相対的なパス解決を使用します：
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- 絶対OSパスをハードコーディングしてはいけません。
- 一時的なJSONファイルを `assets/data/` に置かないでください；すべての静的データは直接リレーショナルSQLiteデータベース `assets/db/pokedex.sqlite` に保存する必要があります。
