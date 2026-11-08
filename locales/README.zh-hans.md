# 🔴 宝可梦库

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | **[🇨🇳 简体中文](README.zh-hans.md)** | [🇹🇼 繁體中文](README.zh-hant.md) | [🇵🇹 Português](README.pt.md) | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** 是一款为宝可梦训练师、收藏者和闪光猎人开发的全面且完全可自定义的伴侣应用，使用 Flutter 开发。无论你是计划区域图鉴、全国图鉴、形态图鉴还是闪光图鉴——PokéVault 都能帮助你轻松跟踪你的进度，并为你的闪光狩猎提供所需的工具。

__徽章块_0____换行变量_0____徽章块_1____换行变量_1____徽章块_2____换行变量_2____徽章块_3____换行变量_3____徽章块_4__

## ✨ 主要功能

* **多Dex管理：**为不同的游戏、世代或您自己的挑战创建尽可能多的跟踪器。
* **详细的形式跟踪：**完全支持区域形式、超级进化、Gigantamax和特殊形式（Pokusan、Vivillon、Unown等）。
* **PC盒和列表视图：**在经典的30槽“PC盒”网格或无缝搜索列表中查看您的神奇宝贝拖放.
* **闪亮跟踪和狩猎计数器：** 分别跟踪普通神奇宝贝和闪亮神奇宝贝。 内置闪亮狩猎计数器，具有实时概率计算、方法选择、阶段历史和带有 AFK 暂停检测功能的会话计时器。
* **🎖️ Dex 完成卡：** 设计、个性化和导出高分辨率成就证书、统计卡和神奇宝贝马赛克，以分享您的进度。
* **匹配球：** 接收社区策划的最佳神奇宝贝球推荐（对于普通 * 和 *闪亮变种）！
* **📊 先进的捕获率计算器：** 精确计算所有世代的捕获概率，包括 *神奇宝贝传奇：阿尔宙斯* 和 *神奇宝贝传奇：Z-A*.
* **🧬 闪亮繁殖和路线计算器：** 计算多阶段繁殖链（包括 Ditto 和幼年神奇宝贝）并显示目标的准确概率后代.
* **📖 详细闪亮的狩猎指南：** 针对特定世代方法的分步说明（例如 PokéRadar、DexNav、三明治食谱）。 
* **🎮 应用内操作和快捷方式概述：** 设置中的自己的屏幕，具有平台自适应快捷方式、鼠标命令和触摸手势。
* **☁️ 云同步和离线优先：** 100% 离线，具有强大的本地 SQLite 数据库。 可选择通过您的私人 Google 云端硬盘进行同步，并具有补丁合并弹性。
* **完全个性化：** 支持深色/浅色模式以及可自定义的强调色和背景颜色。
* **多语言：** 完全提供 13 种语言​​（通过俚语进行 UI）。 此外，根据`pokedex.sqlite`中的10种官方特许经营语言独立选择神奇宝贝特许经营语言（例如具有英语或日语神奇宝贝名称的德语UI）。

## 📸 截图

| 主屏幕 | 电脑盒视图 |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **宝可梦详情与匹配球** | **图鉴创建与筛选** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 入门步骤（本地运行）

### 前提条件
* [Flutter SDK](https://docs.flutter.dev/get-started/install)（建议使用最新稳定版本）
* Dart SDK
* 一个 IDE，如 VS Code 或 Android Studio

### 安装
1. 克隆仓库：
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. 切换到目录：
   ```bash
   cd pokevault
   ```

3. 下载依赖项：
   ```bash
   flutter pub get
   ```

4. 下载外部数据并初始化子模块：
   下载数据库所需的最新数据仓库和维基：
   ```bash
   python3 update_data.py
   ```

5. 生成和优化 SQLite 数据库：
   *PokéVault 需要预编译的 SQLite 数据库来获取宝可梦的基础数据。* 
   运行一体化流水线脚本，以单个命令生成并优化 `assets/db/pokedex.sqlite`：
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(如果你已经拥有外部的网络导出数据并且只想重新构建数据库，可以使用 `--skip-download` 来运行).*

6. 启动应用程序:
   ```bash
   flutter run
   ```

## 🛠️ 创建构建

要创建一个发布版本，请使用以下命令之一：

**安卓 (APK)：**
```bash
flutter build apk --release
```

**Windows：**
```bash
flutter build windows --release
```

**Linux：**
```bash
flutter build linux --release
```

**Linux 应用程序映像：**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**网站:**
```bash
flutter build web --release
```

## 📚 架构和文档
* [架构指南 (`ARCHITECTURE.md`)](ARCHITECTURE.zh-hans.md)：系统架构、提供程序状态管理、DAO 持久性模型、Google Drive 同步协调器、隔离转换桥和测试质量门的详细概述。
* [Git 分支和发布管道(`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.zh-hans.md)：官方 Git 分支模型、分支保护规则、多平台构建（Android APK、Windows Zip、Linux AppImage/tar.gz）和自动化 Beta 预发布.
* [v1.7.0 路线图：语言扩展(`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md)：分离语言、本地 REST 服务器、多模拟器跟踪、桌面 OCR 和移动相机扫描仪的完整技术规范.
* [数据库生成管道(`tool/data_pipeline/locales/README.de.md`)](../tool/data_pipeline/locales/README.zh-hans.md): 离线 PokeAPI 数据准备、抓取器、匹配球导入、索引和数据库编译的文档.
* [开发者和发布工具 (`tool/locales/README.de.md`)](../tool/locales/README.zh-hans.md):自动发布版本管理（“bump_version.py”）、测试套件、代码覆盖率和翻译管道（“translate_all.py”）。

## 🤝 补充数据（社区贡献）
你是否缺少地点信息或者匹配球不合适？你可以在目录 `tool/data_pipeline/` 中的 JSON 文件里补充这些数据（如果存在的话），或者直接通过问题（Issues）/拉取请求（Pull Requests）进行贡献。

如果你想贡献代码、功能或错误修复，请使用 `.github/ISSUE_TEMPLATE` 文件夹中的相应问题模板，并在自己的功能分支上打开一个拉取请求。

## 🙏 致谢与来源
如果没有社区提供的这些优秀资源，这个应用是不可能实现的：
*   [PokeAPI](https://pokeapi.co/): 基础数据和官方艺术作品.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): 社区 Google 表格作为追踪器基础.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): 社区策划的 Excel 表格，用于完美精灵球.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): 捕获率机制.
*   [Google Gemini](https://gemini.google.com): 编程与重构的 AI 辅助.
* 以及更多！

## 📄 许可证
本项目根据 [GNU 通用公共许可证 v3.0 (GPL-3.0)](../LICENSE) 授权。

**免责声明:** 宝可梦及所有相关名称是任天堂、Creatures Inc. 和 GAME FREAK inc. 的商标和©。这是一个免费的、非商业性的粉丝项目，与任天堂没有任何关联，也未得到其支持或赞助。
