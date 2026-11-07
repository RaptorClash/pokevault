#!/usr/bin/env python3
"""PokéVault Automated Translation Pipeline.

Translates UI strings (lib/i18n/strings_de.i18n.json) and documentation
into all configured languages in lib/i18n/languages.json.
Features:
- Free multi-engine translation (Bing, Google, MyMemory) without requiring API keys.
- Optional DeepL API key support when DEEPL_API_KEY is configured.
- MD5 Hash Caching in tool/.translation_cache.json with anti-poisoning safeguards.
- Slang placeholder & plural variable protection.
- Markdown documentation translation with code-block protection, link rewriting, and header preservation.
- Generates lib/i18n/language_registry.g.dart.
- Runs 'dart run slang' to compile Slang classes.
"""

import os
import sys
import json
import re
import hashlib
import subprocess
import argparse
import time
import requests
import threading
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

REPO_ROOT = Path(__file__).resolve().parent.parent
LANGUAGES_JSON_PATH = REPO_ROOT / "lib" / "i18n" / "languages.json"
LANGUAGE_REGISTRY_PATH = REPO_ROOT / "lib" / "i18n" / "language_registry.g.dart"
I18N_DIR = REPO_ROOT / "lib" / "i18n"
MASTER_STRINGS_PATH = I18N_DIR / "strings_de.i18n.json"
CACHE_PATH = REPO_ROOT / "tool" / ".translation_cache.json"

DEFAULT_DOCS = [
    REPO_ROOT / "README.md",
    REPO_ROOT / "tool" / "README.md",
    REPO_ROOT / "tool" / "data_pipeline" / "README.md",
]

# Language code mapping
LANG_MAP = {
    "de": "de",
    "en": "en",
    "fr": "fr",
    "es": "es",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "zh-hans": "zh-Hans",
    "zh-hant": "zh-Hant",
    "pt": "pt",
    "nl": "nl",
    "pl": "pl",
    "ru": "ru",
}

def load_languages_config():
    if not LANGUAGES_JSON_PATH.exists():
        raise FileNotFoundError(f"Languages config missing: {LANGUAGES_JSON_PATH}")
    with open(LANGUAGES_JSON_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

def compute_text_hash(text: str) -> str:
    return hashlib.md5(text.strip().encode("utf-8")).hexdigest()

def mask_placeholders(text: str):
    """Protects Slang parameters, newlines, and code tokens from translation."""
    placeholders = []

    def repl_plural(match):
        idx = len(placeholders)
        placeholders.append(match.group(0))
        return f"__PLURAL_VAR_{idx}__"

    # 1. Protect plural slang constructs: {var, plural, ...}
    text = re.sub(r'\{[^{}]*,\s*plural\s*,[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', repl_plural, text)

    # 2. Protect standard slang parameters: {name}, {count}, {0}, etc.
    def repl_var(match):
        idx = len(placeholders)
        placeholders.append(match.group(0))
        return f"__SLANG_VAR_{idx}__"

    text = re.sub(r'\{[a-zA-Z0-9_]+\}', repl_var, text)

    # 3. Protect newlines
    def repl_nl(match):
        idx = len(placeholders)
        placeholders.append(match.group(0))
        return f"__NL_VAR_{idx}__"

    text = re.sub(r'(\r\n|\n)', repl_nl, text)

    return text, placeholders

def unmask_placeholders(text: str, placeholders):
    """Restores masked tokens back to their original values."""
    for idx, original in enumerate(placeholders):
        pattern = re.compile(rf'__(?:PLURAL|SLANG|NL)_VAR_{idx}__', re.IGNORECASE)
        text = pattern.sub(lambda m, orig=original: orig, text)
    return text

def get_target_doc_path(canonical_file: Path, target_lang: str) -> Path:
    """Returns the destination path for a translated markdown file."""
    parent = canonical_file.parent
    stem = canonical_file.stem
    stem = re.sub(r'\.[a-z]{2}(?:-[A-Za-z]+)?$', '', stem)

    if target_lang.lower() == "en":
        return parent / f"{stem}.md"
    else:
        return parent / "locales" / f"{stem}.{target_lang.lower()}.md"

def get_source_doc_path(canonical_file: Path, source_lang: str) -> Path:
    """Returns the source file path for a given language code."""
    parent = canonical_file.parent
    stem = canonical_file.stem
    stem = re.sub(r'\.[a-z]{2}(?:-[A-Za-z]+)?$', '', stem)

    if source_lang.lower() == "en":
        return parent / f"{stem}.md"

    # Check locales/ first, then fallback to direct parent for backward compatibility
    locales_path = parent / "locales" / f"{stem}.{source_lang.lower()}.md"
    if locales_path.exists():
        return locales_path
    direct_path = parent / f"{stem}.{source_lang.lower()}.md"
    if direct_path.exists():
        return direct_path
    return locales_path

def auto_detect_source_lang(canonical_file: Path, candidate_langs=("en", "de")) -> str:
    """Auto-detects whether German or English was more recently edited."""
    latest_lang = "de"
    latest_mtime = -1.0
    for lang in candidate_langs:
        p = get_source_doc_path(canonical_file, lang)
        if p.exists():
            mtime = p.stat().st_mtime
            if mtime > latest_mtime:
                latest_mtime = mtime
                latest_lang = lang
    return latest_lang

def rewrite_markdown_links(content: str, target_lang: str, is_target_in_locales: bool = False) -> str:
    """Rewrites relative markdown links to point to the translated versions."""
    target_lang_lower = target_lang.lower().replace("_", "-")

    def repl_link(match):
        label = match.group(1)
        url = match.group(2)

        if url.startswith("http://") or url.startswith("https://") or url.startswith("#") or url.startswith("mailto:"):
            return match.group(0)

        # Handle markdown doc links
        if url.endswith(".md"):
            clean_url = re.sub(r'\.[a-z]{2}(?:-[A-Za-z]+)?\.md$', '.md', url)
            clean_url = clean_url.replace("/locales/", "/").replace("locales/", "")
            dir_part, file_part = os.path.split(clean_url)
            stem, _ = os.path.splitext(file_part)

            if stem.startswith("README"):
                if target_lang_lower == "en":
                    target_file = f"{stem}.md"
                else:
                    target_file = f"locales/{stem}.{target_lang_lower}.md"
                new_url = f"{dir_part}/{target_file}" if dir_part else target_file
            else:
                new_url = clean_url

            if is_target_in_locales:
                new_url = f"../{new_url}"

            return f"[{label}]({new_url})"

        # Handle other non-markdown relative links (e.g. scripts, images, etc.)
        if is_target_in_locales and not url.startswith("../"):
            return f"[{label}](../{url})"

        return match.group(0)

    return re.sub(r'\[([^\]]+)\]\(([^)]+)\)', repl_link, content)

def generate_header_language_nav(current_filename: str, languages, current_lang: str, is_in_locales: bool = False) -> str:
    """Generates a top language switcher row for markdown documentation."""
    links = []
    base_name = re.sub(r'\.[a-z]{2}(?:-[A-Za-z]+)?\.md$', '.md', os.path.basename(current_filename))
    base_stem, _ = os.path.splitext(base_name)

    for lang in languages:
        code = lang["code"]
        flag = lang["flag"]
        native = lang["nameNative"]
        code_lower = code.lower()

        if is_in_locales:
            if code_lower == "en":
                target_file = f"../{base_stem}.md"
            else:
                target_file = f"{base_stem}.{code_lower}.md"
        else:
            if code_lower == "en":
                target_file = f"{base_stem}.md"
            else:
                target_file = f"locales/{base_stem}.{code_lower}.md"

        if code_lower == current_lang.lower():
            links.append(f"**[{flag} {native}]({target_file})**")
        else:
            links.append(f"[{flag} {native}]({target_file})")

    return " | ".join(links)

cache_lock = threading.Lock()

def load_cache():
    if CACHE_PATH.exists():
        try:
            with open(CACHE_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_cache(cache):
    with cache_lock:
        with open(CACHE_PATH, "w", encoding="utf-8") as f:
            json.dump(cache, f, ensure_ascii=False, indent=2)

def generate_language_registry_dart(languages):
    """Generates lib/i18n/language_registry.g.dart from languages.json."""
    lines = [
        "// GENERATED CODE - DO NOT MODIFY BY HAND",
        "// Generated from lib/i18n/languages.json via tool/translate_all.py",
        "",
        "class AppLanguageConfig {",
        "  final String code;",
        "  final String flag;",
        "  final String nameNative;",
        "  final String nameEn;",
        "  final bool isPokemonFranchise;",
        "  final String slangCode;",
        "",
        "  const AppLanguageConfig({",
        "    required this.code,",
        "    required this.flag,",
        "    required this.nameNative,",
        "    required this.nameEn,",
        "    required this.isPokemonFranchise,",
        "    required this.slangCode,",
        "  });",
        "}",
        "",
        "class LanguageRegistry {",
        "  static const List<AppLanguageConfig> supportedAppLanguages = [",
    ]

    for lang in languages:
        lines.extend([
            "    AppLanguageConfig(",
            f"      code: '{lang['code']}',",
            f"      flag: '{lang['flag']}',",
            f"      nameNative: '{lang['nameNative']}',",
            f"      nameEn: '{lang['nameEn']}',",
            f"      isPokemonFranchise: {'true' if lang['isPokemonFranchise'] else 'false'},",
            f"      slangCode: '{lang['slangCode']}',",
            "    ),",
        ])

    lines.extend([
        "  ];",
        "",
        "  static List<AppLanguageConfig> get supportedPokemonLanguages =>",
        "      supportedAppLanguages.where((l) => l.isPokemonFranchise).toList();",
        "",
        "  static AppLanguageConfig? findByCode(String code) {",
        "    final normalized = code.toLowerCase().replaceAll('_', '-');",
        "    for (final lang in supportedAppLanguages) {",
        "      if (lang.code.toLowerCase().replaceAll('_', '-') == normalized) {",
        "        return lang;",
        "      }",
        "    }",
        "    return null;",
        "  }",
        "",
        "  static bool isPokemonFranchise(String code) {",
        "    final lang = findByCode(code);",
        "    return lang?.isPokemonFranchise ?? false;",
        "  }",
        "",
        "  static String resolveEffectivePokemonLanguage(",
        "    String appLangCode,",
        "    String pokemonLangCode,",
        "  ) {",
        "    if (pokemonLangCode != 'auto') {",
        "      final explicit = findByCode(pokemonLangCode);",
        "      return explicit?.code ?? pokemonLangCode;",
        "    }",
        "",
        "    if (isPokemonFranchise(appLangCode)) {",
        "      final matched = findByCode(appLangCode);",
        "      return matched?.code ?? appLangCode;",
        "    }",
        "",
        "    return 'en';",
        "  }",
        "}",
    ])

    with open(LANGUAGE_REGISTRY_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated {LANGUAGE_REGISTRY_PATH}")

def free_translate_direct(text: str, target_lang: str, source_lang: str = "de") -> str:
    """Free multi-engine translation using translators without requiring API keys."""
    if not text or not text.strip():
        return text

    target_norm = LANG_MAP.get(target_lang.lower().replace("_", "-"), target_lang)
    source_norm = LANG_MAP.get(source_lang.lower().replace("_", "-"), source_lang)

    # 1. Try Bing
    try:
        import translators as ts
        res = ts.translate_text(text, from_language=source_norm, to_language=target_norm, translator='bing', timeout=10)
        if res and res.strip():
            return res.strip()
    except Exception:
        pass

    # 2. Try Google
    try:
        import translators as ts
        res = ts.translate_text(text, from_language=source_norm, to_language=target_norm, translator='google', timeout=10)
        if res and res.strip():
            return res.strip()
    except Exception:
        pass

    # 3. Try MyMemory
    try:
        from deep_translator import MyMemoryTranslator
        res = MyMemoryTranslator(source=source_norm, target=target_norm).translate(text)
        if res and res.strip():
            return res.strip()
    except Exception:
        pass

    return text

def translate_single_string(text: str, target_lang: str, cache, source_lang: str = "de") -> str:
    """Translates a single string with placeholder protection, caching, and fallback."""
    if not text or not text.strip():
        return text

    h = compute_text_hash(text)
    cache_key = target_lang if source_lang == "de" else f"{source_lang}->{target_lang}"
    lang_cache = cache.setdefault(cache_key, {})
    if h in lang_cache and lang_cache[h] != text:
        return lang_cache[h]

    # Check DeepL API key if user has one configured
    deepl_key = os.environ.get("DEEPL_API_KEY")
    if deepl_key:
        try:
            from deep_translator import DeeplTranslator
            dt = DeeplTranslator(api_key=deepl_key, source=source_lang, target=target_lang)
            masked, placeholders = mask_placeholders(text)
            trans = dt.translate(masked)
            res = unmask_placeholders(trans, placeholders)
            if res and res != text:
                lang_cache[h] = res
                return res
        except Exception:
            pass

    # Free multi-engine translation (Bing -> Google -> MyMemory)
    masked, placeholders = mask_placeholders(text)
    for attempt in range(2):
        try:
            translated = free_translate_direct(masked, target_lang, source_lang=source_lang)
            restored = unmask_placeholders(translated, placeholders)
            if restored and restored != text:
                lang_cache[h] = restored
                return restored
        except Exception:
            if attempt < 1:
                time.sleep(0.5)

    return text

def collect_uncached_strings(source_node, target_node, target_lang, cache, uncached_set):
    """Collects unique strings that need translation, while populating cache from genuine target strings."""
    if isinstance(source_node, dict):
        tgt_dict = target_node if isinstance(target_node, dict) else {}
        for k, v in source_node.items():
            collect_uncached_strings(v, tgt_dict.get(k), target_lang, cache, uncached_set)
    elif isinstance(source_node, list):
        tgt_list = target_node if isinstance(target_node, list) else []
        for i, item in enumerate(source_node):
            tgt_item = tgt_list[i] if i < len(tgt_list) else None
            collect_uncached_strings(item, tgt_item, target_lang, cache, uncached_set)
    elif isinstance(source_node, str):
        text = source_node.strip()
        if not text:
            return
        h = compute_text_hash(source_node)
        lang_cache = cache.setdefault(target_lang, {})
        if target_node is not None and isinstance(target_node, str) and target_node.strip() and target_node != source_node:
            lang_cache[h] = target_node
            return
        if h in lang_cache and lang_cache[h] != source_node:
            return
        uncached_set.add(source_node)

def batch_translate_strings(texts, target_lang, cache, batch_size=30):
    """Translates strings in batches to dramatically reduce HTTP requests and prevent rate-limiting."""
    if not texts:
        return
    lang_cache = cache.setdefault(target_lang, {})
    text_list = list(texts)
    total_batches = (len(text_list) + batch_size - 1) // batch_size
    print(f"  Batch translating {len(text_list)} strings in {total_batches} batches to {target_lang}...")

    DELIM = "\n###\n"
    for batch_idx in range(total_batches):
        batch = text_list[batch_idx * batch_size : (batch_idx + 1) * batch_size]
        masked_list = []
        placeholders_list = []
        for s in batch:
            m, p = mask_placeholders(s)
            masked_list.append(m)
            placeholders_list.append(p)

        joined = DELIM.join(masked_list)
        split_res = []
        try:
            raw_res = free_translate_direct(joined, target_lang)
            split_res = [x.strip() for x in raw_res.split("###")]
        except Exception:
            split_res = []

        if len(split_res) == len(batch):
            for orig, trans_raw, p in zip(batch, split_res, placeholders_list):
                try:
                    restored = unmask_placeholders(trans_raw, p)
                    if restored and restored != orig:
                        lang_cache[compute_text_hash(orig)] = restored
                except Exception:
                    pass
        else:
            # Fallback to individual strings for this batch
            for s in batch:
                translate_single_string(s, target_lang, cache)

        time.sleep(0.15)
        if (batch_idx + 1) % 5 == 0 or batch_idx == total_batches - 1:
            save_cache(cache)
            print(f"    Batch {batch_idx + 1}/{total_batches} done.")

def translate_json_node(source_node, target_node, target_lang, cache, stats, dry_run=False):
    if isinstance(source_node, dict):
        result = {}
        tgt_dict = target_node if isinstance(target_node, dict) else {}
        for k, v in source_node.items():
            result[k] = translate_json_node(v, tgt_dict.get(k), target_lang, cache, stats, dry_run)
        return result
    elif isinstance(source_node, list):
        result = []
        tgt_list = target_node if isinstance(target_node, list) else []
        for i, item in enumerate(source_node):
            tgt_item = tgt_list[i] if i < len(tgt_list) else None
            result.append(translate_json_node(item, tgt_item, target_lang, cache, stats, dry_run))
        return result
    elif isinstance(source_node, str):
        h = compute_text_hash(source_node)
        lang_cache = cache.setdefault(target_lang, {})

        # If existing target string is genuinely translated (not equal to source), use it
        if target_node is not None and isinstance(target_node, str) and target_node.strip() and target_node != source_node:
            lang_cache[h] = target_node
            stats["cache_hits"] += 1
            return target_node
        elif h in lang_cache and lang_cache[h] != source_node:
            stats["cache_hits"] += 1
            return lang_cache[h]
        elif dry_run:
            stats["would_translate"] += 1
            return target_node if (target_node is not None and isinstance(target_node, str) and target_node.strip() and target_node != source_node) else source_node
        else:
            stats["translated"] += 1
            res = translate_single_string(source_node, target_lang, cache)
            time.sleep(0.01)
            return res
    else:
        return source_node

def sync_single_app_language(lang, master_data, cache, dry_run=False):
    code = lang["code"]
    if code == "de":
        return

    target_file = I18N_DIR / f"strings_{code}.i18n.json"
    existing_data = {}
    if target_file.exists():
        try:
            with open(target_file, "r", encoding="utf-8") as f:
                existing_data = json.load(f)
        except Exception:
            existing_data = {}

    stats = {"translated": 0, "cache_hits": 0, "would_translate": 0}
    print(f"Syncing UI strings for {code} ({lang['nameNative']})...", flush=True)

    if not dry_run:
        uncached = set()
        collect_uncached_strings(master_data, existing_data, code, cache, uncached)
        if uncached:
            batch_translate_strings(uncached, code, cache)

    translated_data = translate_json_node(master_data, existing_data, code, cache, stats, dry_run=dry_run)

    if not dry_run:
        with open(target_file, "w", encoding="utf-8") as f:
            json.dump(translated_data, f, ensure_ascii=False, indent=2)
        print(f"  -> Saved {target_file.name} (Hits: {stats['cache_hits']}, New: {stats['translated']})", flush=True)
    else:
        print(f"  [Dry-Run] {target_file.name}: Cache hits={stats['cache_hits']}, Would translate={stats['would_translate']}", flush=True)

def run_app_translations(languages, cache, dry_run=False, target_filter=None, workers=2):
    if not MASTER_STRINGS_PATH.exists():
        print(f"Master file {MASTER_STRINGS_PATH} not found!")
        return

    with open(MASTER_STRINGS_PATH, "r", encoding="utf-8") as f:
        master_data = json.load(f)

    target_langs = [
        l for l in languages
        if l["code"] != "de" and (not target_filter or l["code"].lower() == target_filter.lower())
    ]

    if workers > 1 and len(target_langs) > 1 and not dry_run:
        from concurrent.futures import ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=workers) as executor:
            list(executor.map(lambda l: sync_single_app_language(l, master_data, cache, dry_run), target_langs))
    else:
        for lang in target_langs:
            sync_single_app_language(lang, master_data, cache, dry_run)

    save_cache(cache)

def translate_markdown_file(
    canonical_file: Path,
    target_lang: str,
    languages,
    cache,
    dry_run=False,
    source_lang="de",
    overwrite_en=False
):
    source_file = get_source_doc_path(canonical_file, source_lang)
    if not source_file.exists():
        print(f"Source file {source_file} not found for {canonical_file.name}, skipping.")
        return

    target_file = get_target_doc_path(canonical_file, target_lang)
    target_file.parent.mkdir(parents=True, exist_ok=True)

    if source_file.resolve() == target_file.resolve():
        return

    # Preserve handcrafted English documentation, updating only the language switcher header, unless overwrite_en is requested or source is en
    if target_lang.lower() == "en" and not overwrite_en and target_file.exists() and source_lang.lower() != "en":
        print(f"Preserving existing English doc {target_file.name}, updating language switcher header...", flush=True)
        if not dry_run:
            with open(target_file, "r", encoding="utf-8") as f:
                en_content = f.read()
            is_in_locales = (target_file.parent.name == "locales")
            nav = generate_header_language_nav(target_file.name, languages, "en", is_in_locales=is_in_locales)
            header_nav = f"> **Languages / Sprachen:** {nav}"
            if re.search(r'> \*\*(?:Languages|Sprachen)[^*]*\*\*:?[^\n]+', en_content):
                en_content = re.sub(r'> \*\*(?:Languages|Sprachen)[^*]*\*\*:?[^\n]+', header_nav, en_content)
            elif not en_content.startswith("> **Languages"):
                parts = en_content.split("\n\n", 1)
                if len(parts) == 2:
                    en_content = f"{parts[0]}\n\n{header_nav}\n\n{parts[1]}"
            with open(target_file, "w", encoding="utf-8") as f:
                f.write(en_content)
            print(f"  -> Updated header in {target_file.name}", flush=True)
        return

    print(f"Translating {source_file.name} -> {target_file} ({target_lang})...")

    with open(source_file, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Protect fenced code blocks: ```...```
    code_blocks = []
    def repl_code_block(match):
        idx = len(code_blocks)
        code_blocks.append(match.group(0))
        return f"__CODE_BLOCK_{idx}__"

    protected = re.sub(r'```[\s\S]*?```', repl_code_block, content)

    # 2. Protect HTML comments / blocks
    html_blocks = []
    def repl_html(match):
        idx = len(html_blocks)
        html_blocks.append(match.group(0))
        return f"__HTML_BLOCK_{idx}__"

    protected = re.sub(r'<!--[\s\S]*?-->', repl_html, protected)

    # 3. Protect badges
    badge_blocks = []
    def repl_badge(match):
        idx = len(badge_blocks)
        badge_blocks.append(match.group(0))
        return f"__BADGE_BLOCK_{idx}__"

    protected = re.sub(r'(?:\[!\[[^\]]*\]\([^)]+\)\]\([^)]+\)|!\[[^\]]*\]\([^)]+\))', repl_badge, protected)

    # 4. Split by double newlines into paragraphs
    paragraphs = protected.split("\n\n")
    translated_paras = []
    header_nav = None

    is_target_in_locales = (target_file.parent.name == "locales")

    for para in paragraphs:
        para_stripped = para.strip()
        if not para_stripped:
            translated_paras.append("")
            continue

        if re.match(r'^__(?:CODE|HTML|BADGE)_BLOCK_\d+__$', para_stripped):
            translated_paras.append(para)
            continue

        # If it's the header language switcher, protect it with a placeholder
        if "Languages:" in para or "Sprachen:" in para:
            nav = generate_header_language_nav(target_file.name, languages, target_lang, is_in_locales=is_target_in_locales)
            header_nav = f"> **Languages / Sprachen:** {nav}"
            translated_paras.append("__NAV_HEADER_PLACEHOLDER__")
            continue

        if dry_run:
            translated_paras.append(para)
        else:
            translated = translate_single_string(para, target_lang, cache, source_lang=source_lang)
            translated_paras.append(translated)

    reassembled = "\n\n".join(translated_paras)

    # Restore badges
    for idx, block in enumerate(badge_blocks):
        reassembled = reassembled.replace(f"__BADGE_BLOCK_{idx}__", block)

    # Restore HTML
    for idx, block in enumerate(html_blocks):
        reassembled = reassembled.replace(f"__HTML_BLOCK_{idx}__", block)

    # Restore code blocks
    for idx, block in enumerate(code_blocks):
        reassembled = reassembled.replace(f"__CODE_BLOCK_{idx}__", block)

    # Rewrite internal markdown links
    final_content = rewrite_markdown_links(reassembled, target_lang, is_target_in_locales=is_target_in_locales)

    # Restore language switcher header AFTER link rewriting so its links are preserved!
    if header_nav:
        final_content = final_content.replace("__NAV_HEADER_PLACEHOLDER__", header_nav)

    if not dry_run:
        with open(target_file, "w", encoding="utf-8") as f:
            f.write(final_content)
        print(f"  -> Written {target_file}")

def run_doc_translations(
    languages,
    cache,
    dry_run=False,
    target_filter=None,
    source_lang="auto",
    overwrite_en=False
):
    print("Translating markdown documentation...")
    for canonical_doc in DEFAULT_DOCS:
        if source_lang == "auto":
            effective_source = auto_detect_source_lang(canonical_doc)
            print(f"Auto-detected source language for {canonical_doc.name}: {effective_source}")
        else:
            effective_source = source_lang

        # Update language switcher header in source doc
        src_path = get_source_doc_path(canonical_doc, effective_source)
        if src_path.exists() and not dry_run:
            try:
                with open(src_path, "r", encoding="utf-8") as f:
                    src_content = f.read()
                is_in_locales = (src_path.parent.name == "locales")
                src_nav = generate_header_language_nav(src_path.name, languages, effective_source, is_in_locales=is_in_locales)
                src_header = f"> **Languages / Sprachen:** {src_nav}"
                if re.search(r'> \*\*(?:Languages|Sprachen)[^*]*\*\*:?[^\n]+', src_content):
                    src_content = re.sub(r'> \*\*(?:Languages|Sprachen)[^*]*\*\*:?[^\n]+', src_header, src_content)
                elif not src_content.startswith("> **Languages"):
                    parts = src_content.split("\n\n", 1)
                    if len(parts) == 2:
                        src_content = f"{parts[0]}\n\n{src_header}\n\n{parts[1]}"
                with open(src_path, "w", encoding="utf-8") as f:
                    f.write(src_content)
                print(f"  -> Updated header in {src_path}")
            except Exception as e:
                print(f"  Warning: Could not update header in {src_path}: {e}")

        for lang in languages:
            code = lang["code"]
            if code.lower() == effective_source.lower():
                continue
            if target_filter and code.lower() != target_filter.lower():
                continue
            translate_markdown_file(
                canonical_doc,
                code,
                languages,
                cache,
                dry_run=dry_run,
                source_lang=effective_source,
                overwrite_en=overwrite_en
            )

    save_cache(cache)

def main():
    parser = argparse.ArgumentParser(description="PokéVault Multi-Language Translation Pipeline")
    parser.add_argument("--dry-run", action="store_true", help="Preview without making API translation calls")
    parser.add_argument("--docs-only", action="store_true", help="Only translate documentation files")
    parser.add_argument("--app-only", action="store_true", help="Only translate app UI strings")
    parser.add_argument("--lang", type=str, help="Translate only specific language code (e.g. 'fr')")
    parser.add_argument("--source-lang", type=str, default="auto", help="Source language for doc translation ('auto', 'de', 'en', etc., default: 'auto')")
    parser.add_argument("--overwrite-en", action="store_true", help="Allow overwriting English documentation during translation")
    parser.add_argument("--skip-slang", action="store_true", help="Skip running 'dart run slang'")
    parser.add_argument("--workers", type=int, default=2, help="Number of concurrent language translation workers (default: 2)")
    args = parser.parse_args()

    languages = load_languages_config()
    cache = load_cache()

    print(f"Loaded {len(languages)} languages from {LANGUAGES_JSON_PATH}")
    generate_language_registry_dart(languages)

    if not args.docs_only:
        run_app_translations(languages, cache, dry_run=args.dry_run, target_filter=args.lang, workers=args.workers)

    if not args.app_only:
        run_doc_translations(
            languages,
            cache,
            dry_run=args.dry_run,
            target_filter=args.lang,
            source_lang=args.source_lang,
            overwrite_en=args.overwrite_en
        )

    if not args.skip_slang and not args.dry_run:
        print("Running slang code generation...")
        try:
            subprocess.run(["dart", "run", "slang"], cwd=REPO_ROOT, check=True, shell=True)
            print("Slang code generation complete.")
        except Exception as e:
            print(f"Warning: Slang generation failed: {e}")

if __name__ == "__main__":
    main()
