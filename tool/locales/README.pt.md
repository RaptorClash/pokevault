# 🛠️ Ferramentas de Desenvolvimento e Manutenção do PokéVault

> **Languages / Sprachen:** [🇩🇪 Deutsch](README.de.md) | [🇬🇧 English](../README.md) | [🇫🇷 Français](README.fr.md) | [🇪🇸 Español](README.es.md) | [🇮🇹 Italiano](README.it.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇨🇳 简体中文](README.zh-hans.md) | [🇹🇼 繁體中文](README.zh-hant.md) | **[🇵🇹 Português](README.pt.md)** | [🇳🇱 Nederlands](README.nl.md) | [🇵🇱 Polski](README.pl.md) | [🇷🇺 Русский](README.ru.md)

Este diretório contém scripts auxiliares e automações para desenvolvimento, cobertura de testes, pipeline de tradução, pipeline de dados e gerenciamento de releases.

---

## 📌 Visão geral das ferramentas

| Script / Ferramenta | Linguagem | Descrição |
| :--- | :--- | :--- |
| [`bump_version.py`](../bump_version.py) | Python 3 | Gerenciamento automatizado de versões e builds para `pubspec.yaml` e releases do Git. |
| [`test_bump_version.py`](../test_bump_version.py) | Python 3 | Conjunto de testes unitários para `bump_version.py` (validação SemVer, Regex, flags de CLI). |
| [`translate_all.py`](../translate_all.py) | Python 3 | Pipeline de tradução totalmente automática com múltiplos motores para strings de UI, classes de gírias e documentações. |
| [`run_coverage.ps1`](../run_coverage.ps1) | PowerShell | Executa testes com cobertura de código e gera um relatório LCOV. |
| [`data_pipeline/`](../data_pipeline/locales/README.pt.md) | Python 3 | Scraper, importações JSON e compilação SQLite para `pokedex.sqlite`. |

---

## 🌐 Pipeline de Tradução Automatizada (`translate_all.py`)

O script `translate_all.py` sincroniza e traduz todas as strings do aplicativo (`lib/i18n/strings_*.i18n.json`), gera o registro de idiomas Dart (`lib/i18n/language_registry.g.dart`), compila o Slang e traduz toda a documentação do projeto em subpastas dedicadas `locales/`.

### Principais recursos:
* **Cascata multi-motor gratuita**: usa Bing $\rightarrow$ Google $\rightarrow$ MyMemory sem nenhuma chave de API obrigatória.
* **Suporte DeepL opcional**: Se a variável de ambiente `DEEPL_API_KEY` estiver definida, DeepL é usado como prioridade.
* **Sintaxe e proteção de espaço reservado**: protege parâmetros de gíria (`{name}`, `{count}`), estruturas plurais ICU (`{count, plural, ...}`) e quebras de linha (`\n`) de traduções incorretas.
* **Cache de hash MD5 com anti-envenenamento**: As traduções são armazenadas em `tool/.translation_cache.json` armazenadas em cache persistentemente; retornos idênticos incorretos não são armazenados em cache como válidos.
* **Solicitação em lote**: Combina strings em blocos de 30 para minimizar solicitações HTTP e evitar limites de taxa (HTTP 429).
* **Linguagem de origem flexível e detecção automática (`--source-lang`)**: Detecta automaticamente (`auto`) se o README em inglês ou alemão foi editado pela última vez ou permite forçar manualmente uma fonte idioma.
* **Link Markdown e Reescrita de Navegação**: Ajusta automaticamente os links entre as subpastas `locales/` e o diretório principal e gera a barra de idiomas no cabeçalho dos documentos.

### Comandos importantes do CLI:
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

### Testes para o pipeline de tradução:
```bash
python test/tool/test_translation_pipeline.py
```

---

## 🚀 Ferramenta de Atualização de Versão (`bump_version.py`)

O script `bump_version.py` lê e atualiza a versão em `pubspec.yaml` de acordo com [Versionamento Semântico (SemVer)](https://semver.org/) e incrementa automaticamente o número de build interno do Flutter (`+<build>`).

### 1. Visualização sem alterações de arquivo (`--dry-run`)
Verifica a versão atual e mostra o que seria alterado:
```bash
python tool/bump_version.py 1.6.0 --dry-run
```
*Exemplo de saída:*
```text
Current version in pubspec.yaml: 1.5.0+6
Target version: 1.6.0+7
[DRY-RUN] pubspec.yaml was not modified.
Suggested git commands:
  git add pubspec.yaml
  git commit -m "chore(release): bump version to 1.6.0+7"
  git tag -a v1.6.0 -m "Release v1.6.0"
```

### 2. Aumentar a versão (Número de build automaticamente +1)
```bash
python tool/bump_version.py 1.6.0
```
*Atualizado `version: 1.5.0+6` $
ightarrow$ `version: 1.6.0+7` em `pubspec.yaml`.*

### 3. Atribuir número de build específico (`--build`)
```bash
python tool/bump_version.py 1.6.0 --build 10
```
*Define a versão explicitamente para `1.6.0+10`.*

### 4. Criar automaticamente Git-Commit e Git-Tag (`--commit` & `--tag`)
```bash
# Ändert pubspec.yaml und committet automatisch:
python tool/bump_version.py 1.6.0 --commit

# Oder direkt inklusive annotiertem Git-Tag:
python tool/bump_version.py 1.6.0 --commit --tag
```

### 5. Executar testes para a ferramenta Bump
A lógica do script é protegida por uma suíte de testes unitários independente:
```bash
python tool/test_bump_version.py
```

---

## 📊 Cobertura de Código (`run_coverage.ps1`)

No Windows/PowerShell, a cobertura de testes pode ser medida da seguinte forma:
```powershell
.\tool\run_coverage.ps1
```
Gera o arquivo `coverage/lcov.info` para avaliação adicional.
