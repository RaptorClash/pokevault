# 🔴 PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | **[🇵🇹 Português](README.pt.md)** | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

**PokéVault** é um companheiro abrangente e totalmente personalizável para treinadores de Pokémon, colecionadores e caçadores de Shiny, desenvolvido com Flutter. Não importa se você está planejando um Dex regional, um Dex nacional, um Dex de formas ou um Dex Shiny – o PokéVault te ajuda a acompanhar seu progresso facilmente e fornece as ferramentas necessárias para sua caçada de Shiny.

__BLOCO_DE_INSÍGNIA_0__
__BLOCO_DE_INSÍGNIA_1__
__BLOCO_DE_INSÍGNIA_2__
__BLOCO_DE_INSÍGNIA_3__
__BLOCO_DE_INSÍGNIA_4__

## ✨ Principais funções

* **Gerenciamento Multi-Dex:** Crie quantos rastreadores desejar para diferentes jogos, gerações ou seus próprios desafios.
* **Rastreamento detalhado de formulários:** Suporte completo para formas regionais, mega evoluções, Gigantamax e formas especiais (Pokusan, Vivillon, Unown, etc.).
* **PC box e visualização de lista:** Veja seu Pokémon na grade clássica de 30 slots "PC Box" ou em uma lista pesquisável com arrastar e soltar perfeitamente.
* **Rastreamento Brilhante e Contador de Caça:** Rastreie Pokémon normais e brilhantes separadamente. Contador Shiny Hunt integrado com cálculo de probabilidade em tempo real, seleção de método, histórico de fase e temporizador de sessão com detecção de pausa AFK.
* **🎖️ Cartões de conclusão de Dex:** Projete, personalize e exporte certificados de conquistas de alta resolução, cartões de estatísticas e mosaicos de Pokémon para compartilhar seu progresso.
* **Bolas correspondentes:** Receba recomendações com curadoria da comunidade para as melhores Pokébolas (para o normal *e* variantes brilhantes)!
* **📊 Calculadora avançada de taxa de captura:** Cálculo preciso da probabilidade de captura em todas as gerações, incluindo mecânica especial de *Pokémon Legends: Arceus* e *Pokémon Legends: Z-A*.
* **🧬 Criação brilhante e calculadora de rota:** Calcula cadeias de reprodução em vários estágios (incluindo Ditto e Pokémon bebê) e exibe probabilidades exatas para a prole alvo.
* **📖 Guias detalhados de caça brilhante:** Instruções passo a passo para métodos específicos de geração (por exemplo, PokéRadar, DexNav, receitas de sanduíche).
* **🎮 Visão geral de atalhos e operação no aplicativo:** Tela própria nas configurações com atalhos adaptáveis à plataforma, comandos de mouse e gestos de toque.
* **☁️ Nuvem Sincronização e off-line primeiro:** capacidade 100% off-line com banco de dados SQLite local robusto. Sincronização opcional por meio de seu Google Drive privado com resiliência de mesclagem de patches.
* **Personalização total:** Suporta modo claro/escuro e cores de fundo e detalhes personalizáveis.
* **Multilíngue:** Totalmente disponível em 13 idiomas (UI via gíria). Além disso, seleção independente do idioma da franquia Pokémon (por exemplo, UI em alemão com nomes de Pokémon em inglês ou japonês) com base em 10 idiomas oficiais da franquia em `pokedex.sqlite`.

## 📸 Capturas de tela

| Tela Inicial | Vista Caixa do PC |
| :---: | :---: |
| <img src="../docs/screenshots/de/homescreen/homescreen1.png" width="250"/> | <img src="../docs/screenshots/de/pcboxview/nationaldexboxview.png" width="250"/> <img src="../docs/screenshots/de/pcboxview/nationaldexlistview.png" width="250"/> |
| **Detalhes do Pokémon & Bolas Correspondentes** | **Criação do Dex & Filtros** |
| <img src="../docs/screenshots/de/pokemondetails/pokemondetails.png" width="250"/> | <img src="../docs/screenshots/de/dexcreation/dexcreation1.png" width="250"/> <img src="../docs/screenshots/de/dexcreation/dexcreation2.png" width="250"/> |

## 🚀 Primeiros Passos (Executar Localmente)

### Requisitos
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão estável atual recomendada)
* Dart SDK
* Uma IDE como VS Code ou Android Studio

### Instalação
1. Clonar o repositório:
   ```bash
   git clone https://github.com/RaptorClash/pokevault.git
   ```

2. Mudar para o diretório:
   ```bash
   cd pokevault
   ```

3. Baixar dependências:
   ```bash
   flutter pub get
   ```

4. Baixar dados externos e inicializar submódulos:
   Baixe os repositórios de dados e wikis mais recentes que são necessários para o banco de dados:
   ```bash
   python3 update_data.py
   ```

5. Gerar e otimizar banco de dados SQLite:
   *O PokéVault requer um banco de dados SQLite pré-compilado para os dados básicos de Pokémon.* 
   Execute o script de pipeline tudo-em-um para gerar e otimizar `assets/db/pokedex.sqlite` com um único comando:
   ```bash
   python3 tool/data_pipeline/run_pipeline.py
   ```
   *(Como alternativa, execute com `--skip-download` se você já tiver os dumps da web externos e só quiser reconstruir o banco de dados).*

6. Iniciar o aplicativo:
   ```bash
   flutter run
   ```

## 🛠️ Criar build

Para criar uma versão de lançamento, use um dos seguintes comandos:

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

**Imagem do aplicativo Linux:**
```bash
appimage-builder --recipe AppImageBuilder.yml
```

**Web:**
```bash
flutter build web --release
```

## 📚 Arquitetura e documentação
* [Guia de arquitetura (`ARCHITECTURE.md`)](ARCHITECTURE.pt.md): Visão geral detalhada da arquitetura do sistema, gerenciamento de estado do provedor, modelo de persistência DAO, coordenador de sincronização do Google Drive, ponte de tradução isolada e portas de qualidade de teste.
* [ramificação do Git e pipeline de lançamento (`docs/GIT_WORKFLOW_AND_RELEASES.md`)](../docs/locales/GIT_WORKFLOW_AND_RELEASES.pt.md): modelo oficial de ramificação do Git, regras de proteção de ramificação, compilações multiplataforma (Android APK, Windows Zip, Linux AppImage/tar.gz) e pré-lançamentos beta automatizados.
* [v1.7.0 Roadmap: The Expansão de idioma (`docs/plans/v1_7_0_the_language_expansion.md`)](../docs/plans/v1_7_0_the_language_expansion.md): Especificação técnica completa para idiomas separados, servidor REST local, rastreamento de vários emuladores, OCR de desktop e scanner de câmera móvel.
* [Pipeline de geração de banco de dados (`tool/data_pipeline/locales/README.de.md`)](../tool/data_pipeline/locales/README.pt.md): Documentação de preparação de dados PokeAPI offline, scrapers, importação de bolas correspondentes, índices e compilação de banco de dados.
* [Ferramentas de desenvolvedor e lançamento (`tool/locales/README.de.md`)](../tool/locales/README.pt.md): Gerenciamento automatizado de versões de lançamento (`bump_version.py`), suítes de testes, cobertura de código e pipeline de tradução (`translate_all.py`).

## 🤝 Adicionar dados (Contribuições da comunidade)
Você está sem locais ou as Bolas que correspondem não estão corretas? Você pode adicionar esses dados nos arquivos JSON no diretório `tool/data_pipeline/` (se existirem) ou contribuir diretamente através de Issues/Pull Requests.

Se você quiser contribuir com código, funcionalidades ou correções de bugs, use os modelos de issue correspondentes na pasta `.github/ISSUE_TEMPLATE` e abra um Pull Request em um branch de funcionalidade próprio.

## 🙏 Agradecimentos & Fontes
Este app não teria sido possível sem esses incríveis recursos da comunidade:
*   [PokeAPI](https://pokeapi.co/): Dados básicos e artes oficiais.
*   [Living Dex Inspiration](https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v): Planilhas do Google da comunidade como base de rastreamento.
*   [Matching Balls Guide](https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit?gid=877479959#gid=877479959): Planilha Excel curada pela comunidade para as Pokébolas perfeitas.
*   [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Catch_rate): Mecânicas de taxa de captura.
*   [Google Gemini](https://gemini.google.com): Assistência de IA para programação e refatoração.
* E muitos outros!

## 📄 Licença
Este projeto está licenciado sob a [GNU General Public License v3.0 (GPL-3.0)](../LICENSE).

**Aviso de Responsabilidade:** Pokémon e todos os nomes relacionados são marcas registradas e © da Nintendo, Creatures Inc. e GAME FREAK inc. Este é um projeto de fã gratuito e não comercial, e não tem qualquer ligação com a Nintendo, nem é apoiado ou patrocinado por ela.
