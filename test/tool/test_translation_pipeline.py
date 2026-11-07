import unittest
import sys
import os
import re

# Ensure tool folder is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'tool')))

from translate_all import (
    mask_placeholders,
    unmask_placeholders,
    compute_text_hash,
    rewrite_markdown_links,
    generate_header_language_nav,
    collect_uncached_strings,
    get_target_doc_path,
    get_source_doc_path,
    auto_detect_source_lang,
)

class TestTranslationPipeline(unittest.TestCase):
    def test_mask_and_unmask_slang_variables(self):
        original = "Hallo {name}, du hast {count} Pokémon gefangen!\nGlückwunsch!"
        masked, placeholders = mask_placeholders(original)
        
        # Check that {name}, {count}, and \n were protected
        self.assertNotIn("{name}", masked)
        self.assertNotIn("{count}", masked)
        self.assertNotIn("\n", masked)
        
        # Simulate translation of text surrounding tokens
        simulated_translated = masked.replace("Hallo", "Hello").replace("gefangen", "caught").replace("Glückwunsch", "Congrats")
        
        restored = unmask_placeholders(simulated_translated, placeholders)
        self.assertEqual(restored, "Hello {name}, du hast {count} Pokémon caught!\nCongrats!")

    def test_mask_and_unmask_plural_slang_constructs(self):
        original = "Gefunden: {count, plural, =1{1 Eintrag} other{# Einträge}} im Dex."
        masked, placeholders = mask_placeholders(original)
        self.assertNotIn("{count, plural", masked)
        
        restored = unmask_placeholders(masked, placeholders)
        self.assertEqual(restored, original)

    def test_compute_text_hash(self):
        h1 = compute_text_hash("Hallo Welt")
        h2 = compute_text_hash("Hallo Welt")
        h3 = compute_text_hash("Hello World")
        self.assertEqual(h1, h2)
        self.assertNotEqual(h1, h3)

    def test_rewrite_markdown_links(self):
        doc = "Hier ist die [Dokumentation](tool/README.de.md) und der [Workflow](docs/GIT_WORKFLOW_AND_RELEASES.md)."
        rewritten = rewrite_markdown_links(doc, target_lang="fr", is_target_in_locales=False)
        
        self.assertIn("tool/locales/README.fr.md", rewritten)
        self.assertIn("docs/GIT_WORKFLOW_AND_RELEASES.md", rewritten)

    def test_rewrite_markdown_links_when_target_in_locales(self):
        doc = "Hier ist das Skript [bump_version.py](bump_version.py) und die [Data Pipeline](data_pipeline/README.md)."
        rewritten = rewrite_markdown_links(doc, target_lang="de", is_target_in_locales=True)
        # Sibling files in parent dir must be prefixed with ../
        self.assertIn("../bump_version.py", rewritten)
        # Other doc links must point to their respective locales folder
        self.assertIn("../data_pipeline/locales/README.de.md", rewritten)

    def test_generate_header_language_nav_canonical_and_locales(self):
        languages = [
            {"code": "en", "flag": "🇬🇧", "nameNative": "English"},
            {"code": "de", "flag": "🇩🇪", "nameNative": "Deutsch"},
            {"code": "fr", "flag": "🇫🇷", "nameNative": "Français"},
        ]
        # Canonical English README (outside locales)
        nav_root = generate_header_language_nav("README.md", languages, current_lang="en", is_in_locales=False)
        self.assertIn("**[🇬🇧 English](README.md)**", nav_root)
        self.assertIn("[🇩🇪 Deutsch](locales/README.de.md)", nav_root)
        self.assertIn("[🇫🇷 Français](locales/README.fr.md)", nav_root)

        # Translated README inside locales folder
        nav_locale = generate_header_language_nav("README.de.md", languages, current_lang="de", is_in_locales=True)
        self.assertIn("[🇬🇧 English](../README.md)", nav_locale)
        self.assertIn("**[🇩🇪 Deutsch](README.de.md)**", nav_locale)
        self.assertIn("[🇫🇷 Français](README.fr.md)", nav_locale)

    def test_collect_uncached_strings(self):
        source = {
            "key1": "Hallo Welt",
            "key2": "Speichern",
            "nested": {
                "key3": "Abbrechen"
            }
        }
        # target already has genuine translation for key1, but key2 is equal to source (untranslated), and key3 is missing
        target = {
            "key1": "Hello World",
            "key2": "Speichern"
        }
        cache = {}
        uncached = set()
        collect_uncached_strings(source, target, "en", cache, uncached)
        
        # key1 should have been populated into cache
        h1 = compute_text_hash("Hallo Welt")
        self.assertEqual(cache["en"][h1], "Hello World")
        # key2 and key3 should be marked as uncached
        self.assertIn("Speichern", uncached)
        self.assertIn("Abbrechen", uncached)
        self.assertNotIn("Hallo Welt", uncached)

    def test_doc_path_resolution(self):
        from pathlib import Path
        canonical = Path("tool/README.md")
        
        # English resolves to canonical
        en_target = get_target_doc_path(canonical, "en")
        self.assertEqual(en_target, Path("tool/README.md"))
        
        # Non-English resolves into locales folder
        de_target = get_target_doc_path(canonical, "de")
        self.assertEqual(de_target, Path("tool/locales/README.de.md"))
        
        fr_target = get_target_doc_path(canonical, "fr")
        self.assertEqual(fr_target, Path("tool/locales/README.fr.md"))

    def test_source_doc_resolution(self):
        from pathlib import Path
        canonical = Path("tool/README.md")
        
        # When source is English
        src_en = get_source_doc_path(canonical, "en")
        self.assertEqual(src_en, Path("tool/README.md"))
        
        # When source is German
        src_de = get_source_doc_path(canonical, "de")
        self.assertEqual(src_de, Path("tool/locales/README.de.md"))

    def test_auto_detect_source_lang_by_mtime(self):
        import tempfile
        import time
        from pathlib import Path

        with tempfile.TemporaryDirectory() as tmpdir:
            tmppath = Path(tmpdir)
            canonical = tmppath / "README.md"
            locales_dir = tmppath / "locales"
            locales_dir.mkdir()
            de_file = locales_dir / "README.de.md"

            # 1. German created first, then English updated -> English should be detected
            de_file.write_text("Deutsch", encoding="utf-8")
            time.sleep(0.05)
            canonical.write_text("English", encoding="utf-8")
            self.assertEqual(auto_detect_source_lang(canonical), "en")

            # 2. German touched/updated -> German should be detected
            time.sleep(0.05)
            de_file.write_text("Neues Deutsch", encoding="utf-8")
            self.assertEqual(auto_detect_source_lang(canonical), "de")

if __name__ == '__main__':
    unittest.main()
