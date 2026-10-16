# WMC Handsign

Aplikasi Flutter untuk rekomendasi vertical handover WLAN, 4G, dan 5G berdasarkan kelas trafik. Aplikasi memberi rekomendasi; koneksi aktif tetap ditentukan oleh sistem operasi.

## Progress

| Bagian | Status |
| --- | --- |
| Model data, validasi dan generator jaringan Python | Tersedia |
| Mobilitas Random Waypoint Python dan Dart | Tersedia |
| UI Flutter | Monitor mobilitas tersedia |
| Core Dart: QoS, Fuzzy HF, TOPSIS | Tersedia di `lib/core/handover/` |
| Pembanding TOPSIS langsung dan RSS-only | Tersedia dalam hasil core |
| Hysteresis dan dwell time | Tersedia sebagai modul opsional |
| Sensor Android, generator hybrid Dart, filter EMA | Belum terhubung ke core |
| Konfigurasi eksperimen, Live Monitor, logger, metrik, ekspor | Belum terintegrasi |

Core belum dipasang ke `lib/main.dart`. Folder algoritma Python masih berupa placeholder; implementasi keputusan baru ada di Dart.

## Menjalankan

Dengan Flutter SDK:

```sh
flutter pub get
flutter test test/core/handover_test.dart
flutter run
```

Core hanya memakai pustaka standar Dart. Tes tanpa Flutter:

```sh
dart test_dart/test_core_logic.dart
dart tool/demo_core_logic.dart
dart analyze lib/core/handover
```

Tes standalone mengimpor kode produksi dan memakai kasus yang sama dengan tes Flutter, tanpa menyalin algoritma. Demo memakai data sintetis, bukan hasil pengukuran HP.

Simulator Python lama:

```sh
python -m wmc_simulator --input examples/sample_snapshot.json
python -m unittest discover -s tests -v
```

CLI Python hanya memvalidasi input. `handover_decision: null` pada laporan tersebut tidak menunjukkan status core Dart.

## Alur core

```text
Snapshot + kelas trafik + kecepatan + ID jaringan aktif OS
  -> validasi
  -> FIS 1: data rate, delay, BER -> QoS Factor
  -> FIS 2: QoS, RSS ternormalisasi, kecepatan -> HF
  -> HF > threshold: TOPSIS; selain itu tetap
  -> terbaik = jaringan aktif: tetap
  -> terbaik berbeda: rekomendasi pindah
  -> opsional: hysteresis + dwell time
  -> hasil untuk UI dan logging
```

TOPSIS langsung dihitung setiap tick untuk pembanding. `ranking` Fuzzy-TOPSIS kosong bila HF tidak melewati threshold; `baselineTopsisRanking` tetap tersedia. Jaringan aktif ikut ranking. Seri mempertahankan jaringan aktif, lalu diurutkan berdasarkan ID.

Input kosong atau jaringan aktif hilang/tidak tersedia menghasilkan `insufficientData`. Nilai tidak finite, kecepatan negatif, BER di luar 0–1, dan ID duplikat ditolak. Layer sensor menangani izin ditolak, koneksi terputus, dan data scan kedaluwarsa sebelum evaluasi.

## Integrasi Flutter

```dart
import 'package:project_handsign/core/handover/handover.dart';

final engine = HandoverDecisionEngine();
final stabilizer = RecommendationStabilizer();

final raw = engine.evaluate(
  trafficClass: TrafficClass.conversational,
  velocityMps: velocityMps,
  currentNetworkId: activeNetworkId,
  networks: snapshots,
);
final recommendation = stabilizer.apply(raw, elapsed: stopwatch.elapsed);
```

Buat engine dan stabilizer sekali per eksperimen. Kecepatan berasal dari input manual/controller mobilitas. ID jaringan aktif berasal dari OS, bukan target rekomendasi sebelumnya. Panggil `reset()` pada stabilizer saat eksperimen baru atau konfigurasi berubah. Dwell memakai waktu monoton (`Stopwatch`), bukan jam perangkat. Putusnya aliran sensor harus membatalkan pending dwell melalui `reset()` atau hasil insufficientData.

`NetworkSnapshot` membutuhkan:

| Field | Satuan / isi |
| --- | --- |
| `id` | ID kandidat stabil, misalnya BSSID atau identitas seluler yang konsisten |
| `technology` | `NetworkTechnology.wlan`, `.lte`, `.nr` |
| `rssDbm` | Sinyal dBm; metrik seluler dan rentangnya harus disepakati |
| `dataRateMbps` | Mbps |
| `delayMs` | ms |
| `ber` | Rasio 0–1; `0.01%` = `0.0001` |
| `available` | Kandidat tersedia dan datanya masih layak |
| `parameterSource` | `estimated`, `measured`, `synthetic` untuk parameter QoS |

Generator hybrid FR-03 menghasilkan parameter QoS sebelum membuat snapshot. Gunakan rentang RSS dari konfigurasi yang sama dengan core. EMA dilakukan di layer sinyal; simpan RSS mentah terpisah untuk log. Estimasi QoS tidak boleh diberi label sebagai pengukuran RTT/throughput.

Hasil memuat QoS, HF, threshold, keputusan, alasan, target, ranking, kedua pembanding, dan snapshot input. `result.toJson()` siap digabung dengan timestamp, RSS mentah, hasil probe, serta metadata eksperimen. Core belum menyimpan log/berkas otomatis.

## Referensi dan adaptasi

Referensi utama: Ndegwa et al. (2023), *User Preference-Based Heterogeneous Network Management System for Vertical Handover*, [DOI 10.1155/2023/5551773](https://doi.org/10.1155/2023/5551773).

Paper memakai dua FIS Mamdani dengan Gaussian membership. Default threshold `0.7` berlaku pada semua kelas, dengan pembandingan strict `>`. Threshold per kelas dapat dikonfigurasi sesuai rancangan PRD.

PDF tidak menyediakan parameter Gaussian, rule base lengkap, maupun pengaturan defuzzifikasi numerik. Implementasi memakai rekonstruksi yang dijelaskan di [docs/core-logic.md](docs/core-logic.md); hasil tidak diklaim identik dengan MATLAB penulis. Contoh aturan QoS dan HF yang tertulis pada paper dipertahankan.

Output Mamdani dikalibrasi menjadi permukaan monoton agar QoS/RSS yang membaik tidak menaikkan HF. Kalibrasi dan interpolasi ini merupakan adaptasi tambahan; output produksi berbeda dari centroid mentah. Tes menyapu domain empat kelas QoS dan HF serta kasus threshold hasil audit. Gunakan versi algoritma yang sama untuk seluruh run komparasi; hasil dari versi sebelumnya perlu dihitung ulang.

TOPSIS memakai data rate (benefit), delay dan BER (cost), sesuai PRD v2. Bobot tiga kolom Tabel 2 AHP dinormalisasi ulang. Kode menggunakan bobot tabel, bukan menghitung AHP dari pairwise matrix. Paper aslinya memakai tujuh kriteria.

Dokumen belum seragam mengenai pembanding:

- Timeline lama: TOPSIS utility function.
- PRD Handsign v2, dataflow terbaru, prompt wireframe: RSS-only.
- Paper: pembanding TOPSIS utility function-based dari penelitian lain.

Core menyediakan **TOPSIS langsung** untuk perbandingan dengan Fuzzy-TOPSIS dan **RSS-only ternormalisasi** untuk PRD v2. TOPSIS langsung ini adalah baseline operasional proyek, bukan reproduksi utility function penelitian yang dirujuk penulis. Gunakan input, bobot, kandidat, dan interval yang sama untuk perbandingan. Pisahkan raw Fuzzy-TOPSIS dari versi dengan stabilisasi agar efek dwell tidak dianggap sebagai efek Fuzzy.

PRD umum mata kuliah berisi pilihan topik awal. Presentasi Pekan 3 dan `docs/framework-pekan-3.md` adalah catatan historis fondasi Python. Kebutuhan aplikasi mengikuti PRD Handsign v2 dan dataflow Handsign.

## Verifikasi dan batas hasil

Tes core mencakup Gaussian/centroid, empat kelas QoS, arah perubahan kualitas, threshold, TOPSIS dan invariansi satuan, data invalid, kandidat tidak tersedia, tie, serta hysteresis/dwell. Tes widget counter bawaan di `test/widget_test.dart` masih perlu disesuaikan oleh pekerjaan UI.

Belum ada hasil walk test atau klaim metode lebih unggul. Logger/evaluator perlu mendefinisikan event perubahan rekomendasi, ping-pong, unnecessary recommendation, dan denominator secara konsisten. Karena tidak mengeksekusi handover, aplikasi tidak mengukur failure rate fisik. Probe RTT/throughput dan koneksi OS dipakai untuk validasi independen, bukan mengganti input estimasi secara diam-diam.
