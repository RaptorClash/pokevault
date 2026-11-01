import unittest
import sys
import os

# Add project root to sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from tool.bump_version import parse_version, calculate_next_version, update_pubspec_content

class TestBumpVersion(unittest.TestCase):
    def test_parse_version(self):
        v_name, build = parse_version("1.5.0+6")
        self.assertEqual(v_name, "1.5.0")
        self.assertEqual(build, 6)

        v_name2, build2 = parse_version("2.1.3")
        self.assertEqual(v_name2, "2.1.3")
        self.assertEqual(build2, 1)

    def test_calculate_patch(self):
        next_v = calculate_next_version("1.5.0", 6, "patch")
        self.assertEqual(next_v, "1.5.1+7")

    def test_calculate_minor(self):
        next_v = calculate_next_version("1.5.0", 6, "minor")
        self.assertEqual(next_v, "1.6.0+7")

    def test_calculate_major(self):
        next_v = calculate_next_version("1.5.0", 6, "major")
        self.assertEqual(next_v, "2.0.0+7")

    def test_calculate_explicit_version(self):
        next_v = calculate_next_version("1.5.0", 6, "1.6.0")
        self.assertEqual(next_v, "1.6.0+7")

    def test_calculate_explicit_with_build(self):
        next_v = calculate_next_version("1.5.0", 6, "1.6.0+15")
        self.assertEqual(next_v, "1.6.0+15")

    def test_update_pubspec_content(self):
        sample = """name: pokevault
description: "A new Flutter project."
version: 1.5.0+6

environment:
  sdk: ^3.12.2
"""
        updated = update_pubspec_content(sample, "1.6.0+7")
        self.assertIn("version: 1.6.0+7\n", updated)
        self.assertIn("name: pokevault\n", updated)

if __name__ == '__main__':
    unittest.main()
