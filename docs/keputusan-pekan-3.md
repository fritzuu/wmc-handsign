# Keputusan yang perlu disepakati pada Pekan 3

| Topik | Keputusan saat ini | Yang perlu dilengkapi |
| --- | --- | --- |
| Teknologi | 4G, 5G, WLAN sebagai lingkup awal | Konfirmasi tim/dosen |
| Input | RSS, data rate, delay, BER, velocity | Sumber dan rentang tiap teknologi |
| Kelas trafik | Empat kelas pada tracker proyek | Bobot dan kebutuhan tiap kelas |
| Ambang handover | 0,7 sebagai nilai rancangan | Aturan Fuzzy dan pengujian sensitivitas |
| Interval evaluasi | Belum ditetapkan | Nilai awal dan skenario variasi |
| Baseline | TOPSIS sederhana | Definisi persis dan perlakuan yang adil |
| Hasil simulasi | Log keputusan dan metrik | Rumus tiap metrik evaluasi |

## Kontrak antar modul

- Generator jaringan mengeluarkan `NetworkSnapshot` untuk tiap kandidat pada setiap waktu.
- Mobilitas mengeluarkan kecepatan dan posisi pada waktu yang sama.
- Inisiasi Fuzzy membaca kondisi jaringan saat ini dan mengembalikan skor kebutuhan handover.
- TOPSIS hanya berjalan jika aturan inisiasi terpenuhi; hasilnya adalah peringkat kandidat yang tersedia.
- Simulator mencatat status tetap/berpindah bersama alasan dan parameter input.
- Evaluasi membaca log keputusan untuk menghitung metrik yang telah disepakati.

Data `examples/sample_snapshot.json` hanya dipakai untuk mengecek format dan integrasi awal. Jangan mengutip angkanya sebagai hasil pengukuran.
