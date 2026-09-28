"""Baca input snapshot dari berkas JSON."""

import json
from pathlib import Path

from .models import ScenarioSnapshot


def load_snapshot(path: str | Path) -> ScenarioSnapshot:
    with Path(path).open(encoding="utf-8") as source:
        return ScenarioSnapshot.from_dict(json.load(source))
