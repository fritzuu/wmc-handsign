# Kerangka program Pekan 3

Kerangka ini membagi tanggung jawab kode agar pekerjaan berikutnya bisa ditambahkan tanpa menumpuk semuanya di satu berkas.

| Bagian pada PPT | Lokasi proyek | Status yang dapat dibuktikan |
| --- | --- | --- |
| Kondisi jaringan | `models.py`, `io.py`, `network/candidates.py` | Membaca dan memvalidasi contoh snapshot; menemukan alternatif yang tersedia. |
| Gerak pengguna | `mobility/` | Tempat modul disiapkan; model pergerakan belum dibuat. |
| Keputusan pindah | `fuzzy/`, `topsis/`, `baseline/` | Tempat modul disiapkan; algoritma belum dibuat. |
| Hasil dan uji | `simulation/report.py`, `tests/` | Laporan validasi dan pemeriksaan otomatis tersedia; metrik eksperimen belum ada. |

Alur yang berjalan sekarang:

```text
examples/sample_snapshot.json
  → io.load_snapshot
  → models.ScenarioSnapshot.from_dict
  → network.available_candidates
  → simulation.validation_report
  → tampilan JSON di terminal / berkas output
```

Laporan sengaja memakai `handover_decision: null` agar tidak mengesankan bahwa algoritma perpindahan telah berjalan. Folder untuk pekerjaan pekan selanjutnya sudah tersedia, tetapi belum berisi perhitungan tersebut.
