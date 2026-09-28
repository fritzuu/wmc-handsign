# Fondasi simulator WMC — Pekan 3

Proyek ini menyiapkan antarmuka data untuk simulasi vertical handover 4G, 5G, dan WLAN. Pada tahap ini program **memvalidasi dan menampilkan snapshot jaringan sintetis**. Keputusan handover belum dihitung; modul Fuzzy, TOPSIS, generator, dan evaluasi adalah pekerjaan pekan berikutnya.

## Menjalankan

Memerlukan Python 3.10 atau lebih baru. Tidak ada paket eksternal.

```bash
cd wmc-simulator
python3 -m wmc_simulator --input examples/sample_snapshot.json
python3 -m unittest discover -s tests -v
```

Opsi `--output hasil.json` menyimpan hasil validasi dalam JSON. Nilai di `examples/` adalah **data contoh buatan**, bukan hasil pengukuran atau rentang QoS final. Jika ingin memasang perintah `wmc-simulator` di lingkungan Python, jalankan `python3 -m pip install -e .` dari folder ini.

## Struktur

```text
wmc_simulator/
  models.py       kontrak data dan validasi satuan
  io.py           baca snapshot JSON
  network/        pencarian kandidat; generator profil menyusul Pekan 4
  mobility/       model gerak pengguna (Pekan 4)
  baseline/       metode pembanding (Pekan 5)
  fuzzy/          inisiasi handover (Pekan 6)
  topsis/         pemilihan jaringan (Pekan 7)
  simulation/     laporan validasi; integrasi keputusan menyusul
  evaluation/     metrik dan grafik (Pekan 8–9)
examples/          input sintetis untuk mengecek kontrak data
docs/              keputusan desain dan pekerjaan terbuka
tests/             pemeriksaan validasi input
```

Pemetaan modul dan alur yang sudah berjalan ada di [docs/framework-pekan-3.md](docs/framework-pekan-3.md).

## Kontrak input awal

Satu snapshot berisi `current_network`, `velocity_mps`, `traffic_class`, dan daftar jaringan. Setiap jaringan memiliki `id`, `technology`, `rss_dbm`, `data_rate_mbps`, `delay_ms`, `ber`, dan `available`. Semua angka memakai satuan pada nama kolom; BER adalah rasio 0–1. Kandidat yang tidak tersedia tetap bisa dicatat dengan `available: false`.

## Sebelum implementasi algoritma

Tim perlu memutuskan sumber dan rentang QoS untuk masing-masing teknologi, kelas trafik yang dipakai, interval evaluasi, bobot kriteria, serta definisi baseline. Catat keputusan di [docs/keputusan-pekan-3.md](docs/keputusan-pekan-3.md). Ambang 0,7 dari rancangan paper belum divalidasi untuk simulator ini.
