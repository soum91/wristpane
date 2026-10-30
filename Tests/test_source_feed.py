import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from update_source import update_feed


class WristPaneFeedTests(unittest.TestCase):
    def setUp(self):
        self.feed = json.loads((ROOT / "source.json").read_text(encoding="utf-8"))

    def test_generated_entry_has_direct_release_ipa_and_watch_warning(self):
        result = update_feed(copy.deepcopy(self.feed), build=42, size=1350000, date="2026-10-29", repository="soum91/wristpane")
        app = result["apps"][0]
        self.assertEqual(app["bundleIdentifier"], "com.soum91.wristpane")
        self.assertEqual(app["version"], "0.1.42")
        self.assertEqual(app["versions"][0]["buildVersion"], "42")
        self.assertTrue(app["downloadURL"].endswith("/wristpane-build.42/WristPane-unsigned.ipa"))
        self.assertEqual(app["size"], 1350000)
        self.assertIn("Watch widget", app["localizedDescription"])

    def test_same_build_is_idempotent_and_latest_stays_first(self):
        # The live feed accumulates published versions after every CI build.
        # Test idempotency against a fresh history instead of assuming the
        # committed source.json has no previously published entries.
        empty_feed = copy.deepcopy(self.feed)
        empty_feed["apps"][0]["versions"] = []
        first = update_feed(empty_feed, build=42, size=1350000, date="2026-10-29", repository="soum91/wristpane")
        second = update_feed(first, build=42, size=1350000, date="2026-10-29", repository="soum91/wristpane")
        third = update_feed(second, build=43, size=1351000, date="2026-10-29", repository="soum91/wristpane")
        self.assertEqual(len(third["apps"][0]["versions"]), 2)
        self.assertEqual(third["apps"][0]["version"], "0.1.43")

    def test_rejects_invalid_build_and_wrong_repository(self):
        with self.assertRaises(ValueError):
            update_feed(copy.deepcopy(self.feed), build=0, size=10, date="2026-10-29", repository="soum91/wristpane")
        with self.assertRaises(ValueError):
            update_feed(copy.deepcopy(self.feed), build=1, size=10, date="2026-10-29", repository="other/repo")


if __name__ == "__main__":
    unittest.main()
