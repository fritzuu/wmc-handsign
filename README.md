# WMC Handsign

Monorepo riset dan aplikasi rekomendasi vertical handover (VHO) WLAN, 4G, dan 5G berdasarkan kelas trafik dan preferensi pengguna. Aplikasi memberi rekomendasi handover; koneksi aktif tetap dikontrol oleh sistem operasi.

---

## Struktur Repositori

Proyek ini telah dirapikan ke dalam 3 modul utama:

```text
wmc-handsign/
├── mobile/                      # Aplikasi Flutter (Android, iOS, Web, Desktop)
│   ├── android/                 # Konfigurasi platform Android & sensor native
│   ├── ios/, web/, windows/     # Platform target lainnya
│   ├── lib/                     # Kode sumber aplikasi Flutter & engine core Dart
│   │   ├── core/                # Core VHO engine (FIS Mamdani, TOPSIS, Stabilizer)
│   │   ├── router/              # Routing & navigasi antarmuka
│   │   ├── screens/             # Layar UI (Home, Monitor, Logs, Results, Settings)
│   │   └── theme/               # Tema & styling monochrome
│   ├── test/                    # Pengujian unit & widget Flutter (70 test)
│   ├── test_dart/               # Pengujian standalone Dart tanpa Flutter SDK
│   ├── tool/                    # Skrip pengembang & demo logika core
│   └── pubspec.yaml             # Manifest dependensi Flutter
│
├── simulator/                   # Paket simulasi Python & benchmark baseline
│   ├── wmc_simulator/           # Library simulator (network, mobility, baseline, topsis)
│   ├── tests/                   # Test suite Python unittest (62 test)
│   ├── scripts/                 # Skrip demo interaktif & verifikasi Python ↔ Dart
│   │   ├── demo_*.py            # Demo generator, mobility, topsis
│   │   └── verify_*.py          # Verifikasi kesetaraan algoritma Dart & Python
│   ├── examples/                # Contoh dataset & snapshot sintetis
│   └── pyproject.toml           # Konfigurasi build paket Python
│
├── docs/                        # Spesifikasi teknis, dokumen PRD, dan panduan desain
│   ├── wireframe-prompts-prd.md # Spesifikasi PRD wireframe & prompt UI
│   ├── core-logic.md            # Rekonstruksi logika FIS Mamdani & TOPSIS
│   ├── spesifikasi-parameter-qos.md # Kontrak parameter QoS (4G, 5G, WLAN)
│   ├── baseline-single-topsis.md    # Formulasi baseline Single TOPSIS Utility
│   └── generator-profil-jaringan.md # Pemodelan generator profil heterogen
│
├── wmc-handsign.code-workspace  # Multi-root workspace untuk VS Code
└── README.md                    # Dokumentasi utama repositori
```

---

## Panduan Menjalankan

### 1. Aplikasi Mobile (Flutter)

Masuk ke folder `mobile/`:

```sh
cd mobile
flutter pub get
```

Menjalankan pengujian:
```sh
flutter test
```

Menjalankan pengujian standalone Dart (tanpa runtime Flutter):
```sh
dart test_dart/test_core_logic.dart
dart test_dart/test_hybrid_generator.dart
dart test_dart/test_random_waypoint_standalone.dart
dart test_dart/test_topsis_utility_standalone.dart
dart tool/demo_core_logic.dart
dart analyze lib/core/handover
```

Menjalankan aplikasi ke emulator atau perangkat terhubung:
```sh
flutter run
```

### 2. Simulator Python

Masuk ke folder `simulator/`:

```sh
cd simulator
```

Menjalankan seluruh pengujian unit Python:
```sh
python3 -m unittest discover -s tests -v
```

Menjalankan CLI simulator:
```sh
python3 -m wmc_simulator --input examples/sample_snapshot.json
```

Menjalankan skrip demo dan verifikasi:
```sh
python3 scripts/demo_generator.py
python3 scripts/demo_topsis_baseline.py
python3 scripts/demo_mobility.py
python3 scripts/verify_hybrid_generator.py
python3 scripts/verify_random_waypoint.py
python3 scripts/verify_topsis_utility.py
```

---

## Status Komponen

| Komponen | Lokasi | Status |
| --- | --- | --- |
| Model data, validasi, dan generator jaringan Python | `simulator/wmc_simulator/` | Tersedia |
| Mobilitas Random Waypoint (Python & Dart) | `simulator/` & `mobile/` | Tersedia |
| Core Dart: FIS QoS, FIS HF, TOPSIS | `mobile/lib/core/handover/` | Tersedia |
| Baseline TOPSIS langsung & RSS-only | `mobile/lib/core/` | Tersedia |
| Hysteresis dan Dwell Time stabilizer | `mobile/lib/core/handover/` | Tersedia |
| UI Flutter Multi-Tab (Monitor, Logs, Results, Settings) | `mobile/lib/screens/` | Tersedia |
| Sensor Android & generator hybrid live | `mobile/` | Dalam tahap integrasi |

---

## Alur Logika Rekomendasi (Core VHO)

```text
Snapshot + kelas trafik + kecepatan + ID jaringan aktif OS
  -> validasi input
  -> FIS 1: data rate, delay, BER -> QoS Factor
  -> FIS 2: QoS, RSS ternormalisasi, kecepatan -> Handover Factor (HF)
  -> HF > threshold: TOPSIS; selain itu tetap
  -> terbaik = jaringan aktif: tetap (STAY)
  -> terbaik berbeda: rekomendasi pindah (SWITCH)
  -> opsional: hysteresis + dwell time
  -> hasil untuk UI dan logging
```

TOPSIS langsung dihitung setiap tick untuk pembanding. `ranking` Fuzzy-TOPSIS kosong bila HF tidak melewati threshold; `baselineTopsisRanking` tetap tersedia. Jaringan aktif ikut ranking. Seri mempertahankan jaringan aktif, lalu diurutkan berdasarkan ID.

Input kosong atau jaringan aktif hilang/tidak tersedia menghasilkan `insufficientData`. Nilai tidak finite, kecepatan negatif, BER di luar 0–1, dan ID duplikat ditolak.

---

## Kontrak NetworkSnapshot

| Field | Satuan / Tipe | Keterangan |
| --- | --- | --- |
| `id` | `String` | ID kandidat stabil (misal: BSSID atau cell ID) |
| `technology` | `NetworkTechnology` | `wlan`, `lte`, `nr` |
| `rssDbm` | `double` (dBm) | Sinyal mentah dalam dBm |
| `dataRateMbps` | `double` (Mbps) | Throughput / bandwidth |
| `delayMs` | `double` (ms) | RTT / Latensi |
| `ber` | `double` (rasio 0–1) | Bit Error Rate (`0.01%` = `0.0001`) |
| `available` | `bool` | Status ketersediaan kandidat |
| `parameterSource` | `ParameterSource` | `estimated`, `measured`, `synthetic` |

---

## Referensi Ilmiah

- **Referensi Utama**: Ndegwa et al. (2023), *User Preference-Based Heterogeneous Network Management System for Vertical Handover*, [DOI 10.1155/2023/5551773](https://doi.org/10.1155/2023/5551773).
- **Detail Implementasi & Adaptasi**: Silakan baca dokumen lengkap di [`docs/core-logic.md`](docs/core-logic.md) dan [`docs/spesifikasi-parameter-qos.md`](docs/spesifikasi-parameter-qos.md).
