import unittest
import sys
import os
from pathlib import Path

# Ensure tool folder is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'tool')))

from translate_release_notes import (
    parse_draft_notes,
    format_collapsible_release_notes,
    detect_draft_source_lang,
)

class TestTranslateReleaseNotes(unittest.TestCase):
    def test_parse_draft_notes(self):
        draft = """# PokéVault v1.7.0 Release Notes — "The Language Expansion"

**New Features**
* **The Multi-Language Core:** Decoupled UI language from Pokémon franchise language.

**Improvements & Bug Fixes**
* Performance improvements in PC Box views.
"""
        title, body, footer = parse_draft_notes(draft)
        self.assertEqual(title, '# PokéVault v1.7.0 Release Notes — "The Language Expansion"')
        self.assertIn("**New Features**", body)
        self.assertIn("The Multi-Language Core", body)

    def test_detect_draft_source_lang(self):
        draft_en = """# PokéVault v1.7.0
**New Features**
* Great features!
**Bug Fixes**
* Fixed bug.
"""
        self.assertEqual(detect_draft_source_lang(draft_en), 'en')

        draft_de = """# PokéVault v1.7.0
**Neue Funktionen**
* Tolle Funktionen!
**Verbesserungen & Fehlerbehebungen**
* Fehler behoben.
"""
        self.assertEqual(detect_draft_source_lang(draft_de), 'de')

    def test_format_collapsible_release_notes(self):
        title = '# PokéVault v1.7.0 Release Notes — "The Language Expansion"'
        translations = {
            "en": "**New Features**\n* English feature.",
            "de": "**Neue Funktionen**\n* Deutsches Feature.",
            "fr": "**Nouvelles fonctionnalités**\n* Fonctionnalité française.",
        }
        languages = [
            {"code": "en", "flag": "🇬🇧", "nameNative": "English"},
            {"code": "de", "flag": "🇩🇪", "nameNative": "Deutsch"},
            {"code": "fr", "flag": "🇫🇷", "nameNative": "Français"},
        ]
        footer = "**Full Changelog**: https://github.com/RaptorClash/pokevault/compare/v1.6.1...v1.7.0"

        output = format_collapsible_release_notes(title, translations, languages, footer=footer)

        self.assertTrue(output.startswith('# PokéVault v1.7.0 Release Notes — "The Language Expansion"'))
        self.assertIn("<details>\n<summary>🇬🇧 <b>English</b></summary>\n\n**New Features**\n* English feature.\n\n</details>", output)
        self.assertIn("<details>\n<summary>🇩🇪 <b>Deutsch</b></summary>\n\n**Neue Funktionen**\n* Deutsches Feature.\n\n</details>", output)
        self.assertIn("<details>\n<summary>🇫🇷 <b>Français</b></summary>\n\n**Nouvelles fonctionnalités**\n* Fonctionnalité française.\n\n</details>", output)
        self.assertTrue(output.strip().endswith(footer))

if __name__ == '__main__':
    unittest.main()
