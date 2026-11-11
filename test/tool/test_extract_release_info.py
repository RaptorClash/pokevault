import os
import tempfile
import unittest
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "tool"))

from extract_release_info import (
    extract_release_title,
    get_pubspec_version,
    determine_release_metadata,
)

class TestExtractReleaseInfo(unittest.TestCase):
    def test_extract_title_from_quotes_standard(self):
        content = '# PokéVault v1.7.0 Release Notes — "The Language Expansion"\n\nDetails...'
        title = extract_release_title(content)
        self.assertEqual(title, "The Language Expansion")

    def test_extract_title_from_smart_quotes(self):
        content = '# PokéVault v1.7.0 Release Notes — “The Smart Expansion”\n\nDetails...'
        title = extract_release_title(content)
        self.assertEqual(title, "The Smart Expansion")

    def test_extract_title_fallback_when_no_quotes(self):
        content = "# PokéVault v1.7.0 Release Notes — Simple Title\n\nDetails..."
        title = extract_release_title(content, fallback_tag="v1.7.0")
        self.assertEqual(title, "PokéVault v1.7.0 Release Notes — Simple Title")

    def test_extract_title_empty_content_uses_fallback(self):
        title = extract_release_title("", fallback_tag="v1.7.0")
        self.assertEqual(title, "v1.7.0")

    def test_get_pubspec_version(self):
        yaml_content = "name: pokevault\nversion: 1.7.0+9\ndescription: A test app"
        with tempfile.NamedTemporaryFile("w", delete=False, suffix=".yaml") as f:
            f.write(yaml_content)
            temp_path = f.name
        try:
            version = get_pubspec_version(temp_path)
            self.assertEqual(version, "1.7.0")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    def test_determine_release_metadata_main_branch(self):
        notes_content = '# PokéVault v1.7.0 Release Notes — "The Language Expansion"\n\nBody'
        meta = determine_release_metadata(
            ref_name="main",
            input_tag="",
            notes_content=notes_content,
            pubspec_version="1.7.0",
        )
        self.assertEqual(meta["tag_name"], "v1.7.0")
        self.assertEqual(meta["release_title"], "The Language Expansion")
        self.assertFalse(meta["is_prerelease"])

    def test_determine_release_metadata_beta_tag(self):
        notes_content = '# PokéVault v1.7.0-beta.1 — "Beta Test Release"\n\nBody'
        meta = determine_release_metadata(
            ref_name="v1.7.0-beta.1",
            input_tag="",
            notes_content=notes_content,
            pubspec_version="1.7.0",
        )
        self.assertEqual(meta["tag_name"], "v1.7.0-beta.1")
        self.assertEqual(meta["release_title"], "Beta Test Release")
        self.assertTrue(meta["is_prerelease"])

    def test_determine_release_metadata_explicit_input(self):
        meta = determine_release_metadata(
            ref_name="main",
            input_tag="v1.7.0-rc.1",
            notes_content="No quotes here",
            pubspec_version="1.7.0",
        )
        self.assertEqual(meta["tag_name"], "v1.7.0-rc.1")
        self.assertTrue(meta["is_prerelease"])

if __name__ == "__main__":
    unittest.main()
