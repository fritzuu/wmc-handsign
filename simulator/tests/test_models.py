import json
import unittest
from pathlib import Path

from wmc_simulator.models import ScenarioSnapshot


EXAMPLE = Path(__file__).resolve().parents[1] / "examples" / "sample_snapshot.json"


class ScenarioValidationTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(EXAMPLE.read_text(encoding="utf-8"))

    def test_sample_can_be_loaded(self):
        snapshot = ScenarioSnapshot.from_dict(self.data)
        self.assertEqual(snapshot.current_network, "lte_1")
        self.assertEqual(len(snapshot.networks), 3)

    def test_rejects_duplicate_network_ids(self):
        self.data["networks"][1]["id"] = "lte_1"
        with self.assertRaisesRegex(ValueError, "unik"):
            ScenarioSnapshot.from_dict(self.data)

    def test_rejects_out_of_range_ber(self):
        self.data["networks"][0]["ber"] = 1.5
        with self.assertRaisesRegex(ValueError, "ber harus 0–1"):
            ScenarioSnapshot.from_dict(self.data)

    def test_rejects_unavailable_current_network(self):
        self.data["networks"][0]["available"] = False
        with self.assertRaisesRegex(ValueError, "harus tersedia"):
            ScenarioSnapshot.from_dict(self.data)


if __name__ == "__main__":
    unittest.main()
