# 🛠️ PokéVault 开发与维护工具

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | **[🇨🇳 简体中文](README.zh-hans.md)** | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

此目录包含用于开发、测试覆盖率、翻译管道、数据管道和发布管理的辅助脚本和自动化工具。

---

## 📌 工具概览

| 脚本 / 工具 | 语言 | 描述 |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | 用于 `pubspec.yaml` 和 Git 发布的自动版本和构建管理。 |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | `bump_version.py` 的单元测试套件 (SemVer 验证、正则表达式、CLI 标志)。 |
| [`translate_all.py`](../translate_all.py) | Python 3 | 用于 UI 字符串、俚语类和文档的全自动多引擎翻译流水线。 |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | 执行带代码覆盖率的测试并生成 LCOV 报告。 |
| [`data_pipeline/`](../../data_pipeline/locales/README.zh-hans.md) | Python 3 | 用于 `pokedex.sqlite` 的爬虫、JSON 导入和 SQLite 编译。 |

---

## 🌐 自动化翻译管道 (`translate_all.py`)

脚本 `translate_all.py` 会同步并翻译所有应用字符串（`lib/i18n/strings_*.i18n.json`），生成 Dart 语言注册文件（`lib/i18n/language_registry.g.dart`），编译 Slang，并将所有项目文档翻译到专用的 `locales/` 子文件夹中。

### 主要功能：
* **免费多引擎级联**：使用 Bing $\rightarrow$ Google $\rightarrow$ MyMemory，无需任何强制 API 密钥。
* **可选 DeepL 支持**：如果设置了环境变量 `DEEPL_API_KEY`，则优先使用 DeepL。
* **语法和占位符保护**：保护俚语参数(`{name}`、`{count}`)、ICU 复数结构 (`{count, plural, ...}`) 和错误翻译的换行符 (`\n`)。 
* **具有防中毒功能的 MD5 哈希缓存**：翻译存储在持久缓存的 `tool/.translation_cache.json` 中；不正确的相同返回不会被缓存为有效。
* **请求批处理**：以 30 个块为单位组合字符串，以最大程度地减少 HTTP 请求并避免速率限制 (HTTP 429)。
* **灵活的源语言和自动检测 (`--source-lang`)**：自动检测 (`auto`) 最后编辑的是英语还是德语自述文件，或允许手动强制使用源语言。
* **Markdown 链接和导航重写**：自动调整 `locales/` 子文件夹与主目录之间的链接，并在文档头部生成语言栏。

### 重要的 CLI 命令：
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

### 翻译管道测试：
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 发布版本工具 (`bump_version.py`)

脚本 `bump_version.py` 会读取并更新 `pubspec.yaml` 中的版本，遵循 [语义化版本控制 (SemVer)](https://semver.org/)，并自动递增内部 Flutter 构建号 (`+<build>`)。

### 1. 无文件更改预览（`--dry-run`）
检查当前版本并显示将会更改的内容：
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*输出示例：*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. 提升版本（构建号自动 +1）
```bash
python tool/bump_version.py 1.6.0
```
*在 `pubspec.yaml` 中将 `version: 1.5.0+6` 更新为 `version: 1.6.0+7`.*

### 3. 指定特定的构建号 (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*将版本明确设置为 `1.6.0+10`。*

### 4. 自动创建 Git 提交和 Git 标签 (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. 执行 Bump 工具的测试
脚本的逻辑通过独立的单元测试套件得到保障：
```bash
python tool/test_bump_version.py
```

---

## 📊 代码覆盖率 (`run_coverage.ps1`)

在 Windows/PowerShell 下，测试覆盖率可以如下测量：
```powershell
.\tool\run_coverage.ps1
```
生成文件 `coverage/lcov.info` 以供进一步评估。
