# WMC Simulator — Python Simulation Suite

Paket simulator Python untuk pemodelan jaringan heterogen, mobilitas Random Waypoint (RWP), dan algoritma baseline Single TOPSIS Utility Function.

## Struktur Modul

- `wmc_simulator/` : Paket inti simulator (network, mobility, baseline, topsis, io, models).
- `tests/` : Pengujian unit menggunakan framework `unittest`.
- `scripts/` : Skrip demo interaktif dan verifikasi kesetaraan algoritma Python ↔ Dart.
- `examples/` : Berkas JSON contoh snapshot jaringan heterogen.
- `pyproject.toml` : Konfigurasi paket Python.

## Cara Menjalankan

```sh
# Menjalankan seluruh test suite
python3 -m unittest discover -s tests -v

# Menjalankan CLI simulator dengan contoh snapshot
python3 -m wmc_simulator --input examples/sample_snapshot.json

# Menjalankan skrip demo
python3 scripts/demo_generator.py
python3 scripts/demo_topsis_baseline.py
python3 scripts/demo_mobility.py

# Menjalankan verifikasi
python3 scripts/verify_hybrid_generator.py
python3 scripts/verify_random_waypoint.py
python3 scripts/verify_topsis_utility.py
```
