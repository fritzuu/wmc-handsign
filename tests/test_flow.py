import json
import unittest
from pathlib import Path

from wmc_simulator.models import ScenarioSnapshot
from wmc_simulator.network.candidates import available_candidates
from wmc_simulator.simulation.report import validation_report


EXAMPLE = Path(__file__).resolve().parents[1] / "examples" / "sample_snapshot.json"


class FrameworkFlowTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(EXAMPLE.read_text(encoding="utf-8"))

    def test_available_candidates_exclude_current_and_unavailable(self):
        self.data["networks"][2]["available"] = False
        snapshot = ScenarioSnapshot.from_dict(self.data)
        self.assertEqual([network.id for network in available_candidates(snapshot)], ["nr_1"])

    def test_report_matches_week3_scope(self):
        report = validation_report(ScenarioSnapshot.from_dict(self.data))
        self.assertEqual(report["available_candidates"], ["nr_1", "wlan_1"])
        self.assertEqual(report["status"], "validated_input_only")
        self.assertIsNone(report["handover_decision"])


if __name__ == "__main__":
    unittest.main()
