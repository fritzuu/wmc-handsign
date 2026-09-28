"""Perintah pemeriksaan kontrak data Pekan 3."""

import argparse
import json
from pathlib import Path

from .io import load_snapshot
from .simulation.report import validation_report


def main() -> None:
    parser = argparse.ArgumentParser(description="Validasi snapshot sintetis simulator WMC")
    parser.add_argument("--input", required=True, help="Lokasi snapshot JSON")
    parser.add_argument("--output", help="Simpan hasil validasi dalam JSON")
    args = parser.parse_args()
    try:
        snapshot = load_snapshot(args.input)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        parser.exit(2, f"Input tidak valid: {error}\n")
    result = validation_report(snapshot)
    rendered = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        try:
            Path(args.output).write_text(rendered + "\n", encoding="utf-8")
        except OSError as error:
            parser.exit(2, f"Gagal menyimpan hasil: {error}\n")
    print(rendered)


if __name__ == "__main__":
    main()
