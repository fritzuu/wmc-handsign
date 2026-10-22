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

## Fitur Unggulan Terkini

- **Pelabelan Jaringan Ramah Pengguna**: Mengganti istilah telekomunikasi kaku (`NR`, `SmallCell`, `LTE Macro`, `WLAN AP`) menjadi nama yang intuitif: **Wi-Fi / WLAN**, **4G LTE**, dan **5G Super Cepat**.
- **Peta 2D Interaktif & Visualisasi Jejak Langkah**: Visualisasi real-time pergerakan pengguna, jangkauan radius sinyal tiap access point, garis koneksi aktif, jejak langkah (breadcrumb trajectory), dan indikator kecepatan.
- **Pemodelan Rintangan Fisik (Obstacle & NLoS)**:
  - Kompleks gedung beton setinggi area perkotaan yang meredam sinyal gelombang mikro 5G secara drastis ($-24\text{ dB}$, drop throughput 85%).
  - Memperagakan keunggulan penetrasi frekuensi sub-GHz 4G LTE sebagai penyelamat konektivitas saat berada di dalam ruangan/gedung.
- **Skenario Preset 1-Klik**:
  - `📶 Wi-Fi Terbaik`: Pengguna tinggal santai di Coworking Cafe Hub dengan throughput stabil, latensi rendah, dan biaya hemat.
  - `⚡ 5G Terbaik (LoS)`: Pengguna berada di Tech Plaza terbuka bebas hambatan dengan Line-of-Sight prima (~800+ Mbps).
  - `🛡️ 4G Terbaik (Rintangan)`: Pengguna berada di dalam gedung beton tebal di mana 4G menjadi konektivitas terbaik.
  - `🔄 Sirkuit Dinamis`: 15 titik multi-zona loop yang mengitari seluruh kawasan secara alami.
- **Pola Mobilitas Alami (Natural Campus Mobility)**:
  - `wifiDwell`: Dwelling mikro realistis di dalam kafe/kantor ($0.8 - 1.3\text{ m/s}$ dengan jeda $10 - 25\text{ detik}$).
  - `fiveGOpenPlaza`: Mobilitas ruang terbuka.
  - `fourGObstacleShelter`: Mobilitas dalam gedung beton.
  - `naturalCircuit`: Loop kawasan perkotaan/kampus.

---

## Panduan Instalasi & Menjalankan (Multi-Platform)

Repositori ini dapat dijalankan pada **macOS**, **Linux**, dan **Windows**.

### Prasyarat Umum

1. **Flutter SDK**: Versi $\ge 3.24.0$ ([flutter.dev](https://flutter.dev/docs/get-started/install)).
2. **Dart SDK**: Termasuk otomatis di dalam Flutter SDK.
3. **Python**: Versi $\ge 3.10$ ([python.org](https://www.python.org/downloads/)).
4. **Git**: Untuk clone repositori.

---

### A. Menjalankan di macOS

#### 1. Persiapan Toolchain macOS

Pastikan Xcode Command Line Tools sudah terpasang:

```bash
xcode-select --install
```

Verifikasi instalasi Flutter:

```bash
flutter doctor
```

#### 2. Menjalankan Aplikasi Mobile / Desktop (macOS)

```bash
cd mobile
flutter pub get

# Menjalankan pengujian (86 tests)
flutter test

# Menjalankan aplikasi langsung di desktop macOS
flutter run -d macos

# Atau menjalankan di iOS Simulator
open -a Simulator
flutter run -d iPhone
```

#### 3. Menjalankan Simulator Python di macOS

```bash
cd simulator
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Menjalankan unit test Python (62 tests)
python3 -m unittest discover -s tests -v

# Menjalankan CLI & Skrip Demo
python3 -m wmc_simulator --input examples/sample_snapshot.json
python3 scripts/demo_generator.py
python3 scripts/demo_topsis_baseline.py
```

---

### B. Menjalankan di Linux (Ubuntu / Debian / Fedora)

#### 1. Persiapan Dependensi Sistem Linux

Untuk menjalankan Flutter di Linux Desktop, instal dependensi C++ dan GTK:

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev python3-venv python3-pip

# Fedora
sudo dnf install -y clang cmake ninja-build pkgconf-pkg-config gtk3-devel xz-devel python3-virtualenv
```

Verifikasi kesiapan Flutter:

```bash
flutter doctor
```

#### 2. Menjalankan Aplikasi Flutter di Linux

```bash
cd mobile
flutter pub get

# Menjalankan unit test
flutter test

# Menjalankan aplikasi target Linux Desktop
flutter run -d linux

# Atau menjalankan target Web / Android Device
flutter run -d chrome
```

#### 3. Menjalankan Simulator Python di Linux

```bash
cd simulator
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Menjalankan seluruh test suite
python3 -m unittest discover -s tests -v

# Menjalankan demo mobilitas & evaluasi TOPSIS
python3 scripts/demo_mobility.py
python3 scripts/demo_generator.py
```

---

### C. Menjalankan di Windows (Windows 10 / 11)

#### 1. Persiapan Toolchain Windows

- Pasang **Visual Studio 2022** (Community Edition) dengan workload **"Desktop development with C++"** (diperlukan untuk Flutter Windows Desktop).
- Buka **PowerShell** sebagai Administrator atau Terminal standar:

```powershell
flutter doctor
```

#### 2. Menjalankan Aplikasi Flutter di Windows (PowerShell / CMD)

```powershell
cd mobile
flutter pub get

# Menjalankan unit test (86 tests)
flutter test

# Menjalankan aplikasi target Windows Desktop native (.exe)
flutter run -d windows

# Atau menjalankan target Chrome / Edge Web
flutter run -d edge
```

#### 3. Menjalankan Simulator Python di Windows (PowerShell)

```powershell
cd simulator
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e .

# Menjalankan test suite Python
python -m unittest discover -s tests -v

# Menjalankan CLI simulator & demo
python -m wmc_simulator --input examples\sample_snapshot.json
python scripts\demo_generator.py
python scripts\demo_topsis_baseline.py
```

---

### D. Skrip Standalone Dart (Tanpa Flutter Engine)

Dapat dijalankan di semua OS (macOS, Linux, Windows) langsung dari folder `mobile/`:

```bash
cd mobile
dart test_dart/test_core_logic.dart
dart test_dart/test_hybrid_generator.dart
dart test_dart/test_random_waypoint_standalone.dart
dart test_dart/test_topsis_utility_standalone.dart
dart tool/demo_core_logic.dart
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
