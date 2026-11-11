# Pipeline de Geração de Banco de Dados do PokéVault (`tool/data_pipeline/`)

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | **[🇵🇹 Português](README.pt.md)** | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Este diretório contém o pipeline completo de dados offline para a criação e otimização do banco de dados de referência SQLite `assets/db/pokedex.sqlite` para o PokéVault.

---

## 1. Visão geral & Objetivo

PokéVault funciona com base no princípio **Offline-First**. Todos os dados estáticos da franquia (valores base dos Pokémon, formas alternativas, taxas de captura, fitas, conjuntos de ataques aprendidos, locais de encontro, bloqueios Shiny, nomes de espécies em vários idiomas e Pokébolas compatíveis) são pré-agregados em um banco de dados SQLite no momento da compilação e entregues com o aplicativo.

Assim, consultas lentas à API em tempo de execução são eliminadas e os usuários podem usar o aplicativo em qualquer lugar sem conexão com a internet.

---

## 2. Requisitos do Sistema & Configuração

- **Python 3.10 ou superior**
- **Git** com suporte a submódulos
- Instalar pacotes Python necessários:
  ```bash
  pip install beautifulsoup4 openpyxl requests translators deep-translator
  ```
- Inicializar submódulos Git:
  ```bash
  git submodule update --init --recursive
  ```

---

## 3. Fontes de dados & Estrutura de diretórios

O pipeline combina dados de várias fontes confiáveis:

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
 - Fornece arquivos JSON estruturados para dados mestres de Pokémon, estatísticas básicas, tipos, habilidades, conjuntos de aprendizagem de movimentos, nomes de espécies multilíngues e evoluções.
2. **[PokéWiki](https://www.pokewiki.de/) (`*.html`)**:
 - Nomes alemães, bandas e descrições de personagens ('lista de todas as bandas', 'personagens'), diferenças de gênero e Pokémon brilhantes.
3. **[Bulbapedia](https://bulbapedia.bulbagarden.net/) (`*.html`)**:
 - Listas globais de fitas, trocas no jogo e Pokémon Venenosos em todas as gerações (salvos como HTML offline).
4. **[Bisafans](https://www.bisafans.de/) (`*.html`)**:
 - Listas detalhadas de presentes e negociações específicas da edição de Kanto a Paldea e Z-A.
5. **Planilha da comunidade (`Legal_Matching_Pokeballs.xlsx`)**:
 - Matriz detalhada de todos os Pokémon capturáveis ​​por edição e estética de Pokébola correspondente.

---

## 4. Execução rápida completa (Executor tudo-em-um)

Para executar todo o pipeline com todos os scripts na ordem correta com um único comando, use `run_pipeline.py`:

```bash
# Gesamte Pipeline ausführen (Downloads + Submodule + DB Build + Mehrsprachigkeit + Optimierung):
python tool/data_pipeline/run_pipeline.py

# Alternativ: Nur Datenbank kompilieren & optimieren (ohne erneutes Web-Scraping):
python tool/data_pipeline/run_pipeline.py --skip-download
```

Este Runner cuida automaticamente de:
1. `update_data.py` (atualizar dados externos & submódulos Git)
2. `build_database.py` (gerar `assets/db/pokedex.sqlite` com dados básicos)
3. `update_pokemon_languages.py` (sincroniza todos os 10 idiomas da franquia para todas as espécies)
4. `update_evolutions_db.py` (enriquecer árvores de evolução)
5. `update_cap_locks_and_trades.py` (registrar bloqueios de chapéu, cosplay & trocas)
6. `optimize_databases.py` (criar índices de cobertura, `ANALYZE`, `VACUUM`)

---

## 5. Processo manual (Passos individuais)

Caso determinados scripts precisem ser executados manualmente:

### Passo 1: Atualizar Dados Brutos Externos & Submódulos
```bash
python update_data.py
```
*Baixa os caches HTML atuais, puxa o mais recente `Legal_Matching_Pokeballs.xlsx` e atualiza o submódulo `api-data` para a versão mais recente.*

### Etapa 2: Construir o banco de dados principal do SQLite
```bash
python tool/data_pipeline/build_database.py
```
*Cria `assets/db/pokedex.sqlite`, lê todos os 1.025+ Pokémon e 250+ formas e agrega mais de 500 bloqueios Shiny.*

### Passo 3: Sincronizar nomes de Pokémon em vários idiomas
```bash
python tool/data_pipeline/update_pokemon_languages.py
```
*Lê dinamicamente todos os idiomas da franquia a partir de `lib/i18n/languages.json`, adiciona colunas ausentes (`name_fr`, `name_ja`, etc.) usando `ALTER TABLE` e preenche os nomes a partir dos JSONs offline da PokeAPI.*

### Etapa 4: Enriquecer árvores de desenvolvimento
```bash
python tool/data_pipeline/update_evolutions_db.py
```
*Calcula árvores de desenvolvimento, ramificações e gatilhos.*

### Passo 5: Inserir Caps, Cosplay e Trocas
```bash
python tool/data_pipeline/update_cap_locks_and_trades.py
```
*Insere Pikachu com boné, formas de cosplay e trocas em `assets/db/pokedex.sqlite` e `database/pokedex.sqlite`.*

### Passo 6: Criar Índices, Otimizar & VACUUM
```bash
python tool/data_pipeline/optimize_databases.py
```
*Cria índices de cobertura, executa `ANALYZE`, `PRAGMA optimize;` e `VACUUM`.*

---

## 6. Visão geral das tabelas em `pokedex.sqlite`

| Tabela | Descrição | Índices importantes |
|---|---|---|
| `Pokémon` | Dados básicos para todos os mais de 1.025 Pokémon, incluindo 10 colunas de idiomas da franquia (`name_de`, `name_en`, `name_fr`, `name_es`, `name_it`, `name_ja`, `name_ko`, `name_zh_hans`, `name_zh_hant`) | `CHAVE PRIMÁRIA (id)` |
| `formulários` | Formas alternativas, Mega, G-Max, Regional | `idx_forms_poke (pokemon_id)` |
| `dex_pedidos` | Pedidos Pokédex Regionais | `idx_dex_orders_poke_dex (pokemon_id, dex_name, order_index)` |
| `dexes_especiais` | Dexes especiais (por exemplo, Lendários, Ultra Beasts) | `idx_special_dexes_poke_dex (pokemon_id, dex_name)` |
| `pokemon_moves` | Ataque conjuntos de aprendizagem de todas as versões | `idx_pokemon_moves_poke (pokemon_id, version_group)` |
| `pokemon_abilities` | Habilidades e habilidades ocultas | `idx_pokemon_abilities_poke (pokemon_id)` |
| `encontros` | Locais e tipos de encontro | `idx_encounters_poke (pokemon_id, version_group)` |
| `evolução` | Árvores de desenvolvimento completas | `CHAVE PRIMÁRIA (species_id)` |
| `fitas` | Fitas de todas as gerações | `CHAVE PRIMÁRIA (id)` |
| `marcas` | Personagens de todas as edições | `CHAVE PRIMÁRIA (id)` |
| `brilhantes_locks` | Todos os bloqueios brilhantes (global e edição) | `CHAVE PRIMÁRIA (pokemon_id, form_name, game_version)` |
| `bolas_legais` | Pokébolas legais por Pokémon e edição | `idx_legal_balls_poke (pokemon_id, gen)` |

---

## 7. Verificação & Garantia de Qualidade

Após cada execução do pipeline, deve-se garantir que o banco de dados gerado esteja completo e sem erros:

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

## 8. Convenções de Caminho & Desenvolvimento

Todos os scripts neste diretório usam resolução de caminho dinâmica e relativa:
```python
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = BASE_DIR.parent.parent
```
- Nunca codificar caminhos absolutos do sistema operacional.
- Não colocar arquivos JSON temporários em `assets/data/`; todos os dados estáticos devem ir diretamente para o banco de dados relacional SQLite `assets/db/pokedex.sqlite`.
