# Dokumentasi Baseline Algorithm: Single TOPSIS Utility Function

Dokumen ini menjelaskan rancangan, formulasi matematis, kebijakan validasi, konfigurasi bobot, dan petunjuk penggunaan algoritma baseline **Single TOPSIS Utility Function** (`wmc_simulator.baseline.topsis_utility` dan `lib/core/baseline/topsis_utility.dart`).

---

## 1. Tujuan dan Peran Algoritma Baseline

Dalam penelitian sistem pendukung keputusan *Vertical Handover* (VHO) jaringan heterogen (4G LTE, 5G NR, WLAN), algoritma **Single TOPSIS Utility Function** berperan sebagai **pembanding standar (*baseline*)** independen terhadap algoritma primer (*Adaptive Fuzzy-TOPSIS*).

### Karakteristik Baseline:
* **Fungsi Utilitas Tunggal (*Single-Stage Utility Function*)**: Seluruh kriteria QoS (RSS, Data Rate, Delay, BER) diproses secara langsung ke dalam satu matriks keputusan TOPSIS konvensional tanpa penyaringan *fuzzy inference*.
* **Evaluasi Relatif**: Menghitung koefisien kedekatan relatif (*relative closeness*) $C_i \in [0.0, 1.0]$ terhadap solusi ideal positif ($A^+$) dan solusi ideal negatif ($A^-$).
* **Pemeringkatan Deterministik**: Mengurutkan kandidat jaringan dari skor utilitas tertinggi (peringkat 1) hingga terendah.

---

## 2. Kriteria Evaluasi dan Arah Preferensi

Secara default, algoritma mendukung 4 kriteria kualitas jaringan heterogen:

| Kriteria | Simbol | Satuan | Jenis Kriteria | Arah Optimasi | Alasan Teknis |
|---|---|---|---|---|---|
| **Data Rate** | DR | Mbps | **Benefit** | Maksimum ($v_j^+ = \max$) | Throughput lebih tinggi memberikan kecepatan transfer data yang lebih cepat. |
| **Delay** | D | ms | **Cost** | Minimum ($v_j^+ = \min$) | Latensi transmisi lebih rendah memberikan responsivitas layanan yang lebih baik. |
| **Bit Error Rate** | BER | rasio $[0, 1]$ | **Cost** | Minimum ($v_j^+ = \min$) | Rasio bit salah lebih kecil menjamin keandalan integritas transmisi data. |
| **RSS** | RSS | dBm | **Benefit** | Maksimum ($v_j^+ = \max$) | Daya sinyal yang lebih kuat (lebih mendekati 0 atau kurang negatif) menunjukkan koneksi radio yang lebih stabil. |

> [!NOTE]
> **Penanganan Nilai RSS Negatif (dBm)**:
> Pada skala dBm, nilai sinyal adalah bilangan negatif (misal $-50\text{ dBm}$ vs $-90\text{ dBm}$). Karena $-50 > -90$, operator $\max$ matematis secara alami memilih $-50\text{ dBm}$ sebagai solusi ideal positif untuk kriteria benefit. Normalisasi vektor Euclidean memperhitungkan kuadrat nilai tanpa merusak urutan ordinal.

---

## 3. Mekanisme Pembobotan Kriteria

Algoritma mendukung pembobotan yang dapat dikonfigurasi secara fleksibel:
1. **Validasi Bobot**: Seluruh bobot wajib bernilai non-negatif ($w_j \ge 0$) dan berhingga. Konfigurasi dengan bobot negatif atau total bobot nol akan ditolak dengan `ValueError`.
2. **Normalisasi Otomatis**: Jika jumlah bobot tidak tepat bernilai $1.0$, algoritma secara transparan menormalisasinya:
   $$w_j^{\text{norm}} = \frac{w_j}{\sum_{k=1}^n w_k}$$
3. **Bobot Default Kelas Aplikasi (PRD v2.0 / Ndegwa et al., 2023)**:
   * **Conversational (VoIP/Gaming)**: $w_{\text{delay}} = 0.50$, $w_{\text{ber}} = 0.30$, $w_{\text{rate}} = 0.20$
   * **Streaming (Video/Audio)**: $w_{\text{rate}} = 0.50$, $w_{\text{delay}} = 0.30$, $w_{\text{ber}} = 0.20$
   * **Interactive (Web/Browsing)**: $w_{\text{rate}} = 0.40$, $w_{\text{delay}} = 0.35$, $w_{\text{ber}} = 0.25$
   * **Background (Download/Sync)**: $w_{\text{rate}} = 0.60$, $w_{\text{delay}} = 0.20$, $w_{\text{ber}} = 0.20$

---

## 4. Tahapan Matematis TOPSIS

```
Matriks Keputusan X
        │
        ▼ (Tahap 1 & 2)
Normalisasi Vektor: r_ij = x_ij / √(Σ x_kj²)
        │
        ▼ (Tahap 3)
Matriks Terbobot: v_ij = w_j · r_ij
        │
        ▼ (Tahap 4)
Solusi Ideal: A⁺ (max benefit / min cost) & A⁻ (min benefit / max cost)
        │
        ▼ (Tahap 5)
Jarak Separasi: D_i⁺ = √(Σ(v_ij - v_j⁺)²) & D_i⁻ = √(Σ(v_ij - v_j⁻)²)
        │
        ▼ (Tahap 6)
Skor Utilitas: C_i = D_i⁻ / (D_i⁺ + D_i⁻)
        │
        ▼ (Tahap 7)
Perankingan Menurun (Rank 1 = C_i tertinggi)
```

### Tahap 1 — Pembentukan Matriks Keputusan ($X$)
Menyusun matriks berukuran $m \times n$, di mana $m$ adalah jumlah alternatif dan $n$ adalah jumlah kriteria:
$$X = \begin{bmatrix} x_{11} & x_{12} & \dots & x_{1n} \\ x_{21} & x_{22} & \dots & x_{2n} \\ \vdots & \vdots & \ddots & \vdots \\ x_{m1} & x_{m2} & \dots & x_{mn} \end{bmatrix}$$

### Tahap 2 — Normalisasi Vektor ($R$)
Setiap elemen dinormalisasi berdasarkan panjang vektor Euclidean kolomnya:
$$r_{ij} = \frac{x_{ij}}{\sqrt{\sum_{k=1}^m x_{kj}^2}}$$
*Penanganan Kasus Tepi*: Jika seluruh nilai pada kolom $j$ bernilai nol ($\sum x_{kj}^2 = 0$), maka $r_{ij} = 0.0$ ditetapkan secara eksplisit untuk mencegah pembagian nol (`ZeroDivisionError`).

### Tahap 3 — Pembobotan Matriks ($V$)
Mengalikan matriks ternormalisasi dengan bobot kriteria masing-masing:
$$v_{ij} = w_j \cdot r_{ij}$$

### Tahap 4 — Penentuan Solusi Ideal Positif ($A^+$) dan Negatif ($A^-$)
* **Solusi Ideal Positif ($A^+$)**:
  $$v_j^+ = \begin{cases} \max_i v_{ij}, & \text{jika kriteria } j \text{ adalah Benefit} \\ \min_i v_{ij}, & \text{jika kriteria } j \text{ adalah Cost} \end{cases}$$
* **Solusi Ideal Negatif ($A^-$)**:
  $$v_j^- = \begin{cases} \min_i v_{ij}, & \text{jika kriteria } j \text{ adalah Benefit} \\ \max_i v_{ij}, & \text{jika kriteria } j \text{ adalah Cost} \end{cases}$$

### Tahap 5 — Perhitungan Jarak Separasi Euclidean ($D_i^+$ dan $D_i^-$)
$$D_i^+ = \sqrt{\sum_{j=1}^n (v_{ij} - v_j^+)^2}, \quad D_i^- = \sqrt{\sum_{j=1}^n (v_{ij} - v_j^-)^2}$$

### Tahap 6 — Perhitungan Skor Utilitas Kedekatan Relatif ($C_i$)
$$C_i = \frac{D_i^-}{D_i^+ + D_i^-}$$
*Penanganan Kasus Tepi*:
* Jika $D_i^+ + D_i^- = 0$ (terjadi ketika seluruh alternatif identik di semua kriteria), skor utilitas ditetapkan $C_i = 0.5$ untuk menjaga stabilitas perankingan tanpa memicu NaN.
* Jika hanya terdapat $1$ alternatif ($m = 1$), skor utilitas ditetapkan $C_i = 1.0$ dan alternatif tersebut otomatis menempati peringkat 1.

### Tahap 7 — Perankingan Alternatif
Alternatif diurutkan secara menurun (*descending*) berdasarkan $C_i$. Jika terjadi skor seri (*tied scores*), urutan asli input dipertahankan secara stabil (*deterministic tie-handling*).

---

## 5. Contoh Perhitungan Manual yang Dapat Diverifikasi Independen

Berikut adalah contoh perhitungan langkah demi langkah yang dapat diverifikasi secara manual dan diuji oleh unit test `test_1_manual_verifiable_matrix_intermediate_steps`:

### Input Matriks:
* $A_1$ (4G): $\text{Rate} = 30\text{ Mbps}$, $\text{Delay} = 40\text{ ms}$, $\text{BER} = 0.001$
* $A_2$ (5G): $\text{Rate} = 100\text{ Mbps}$, $\text{Delay} = 10\text{ ms}$, $\text{BER} = 0.00001$
* $A_3$ (WLAN): $\text{Rate} = 50\text{ Mbps}$, $\text{Delay} = 25\text{ ms}$, $\text{BER} = 0.0001$
* Bobot: $w = [0.5, 0.3, 0.2]$ untuk $[\text{Rate (B)}, \text{Delay (C)}, \text{BER (C)}]$

### Langkah 1: Pembagi Normalisasi Vektor
* $\text{Denom}_{\text{Rate}} = \sqrt{30^2 + 100^2 + 50^2} = \sqrt{13400} \approx 115.75837$
* $\text{Denom}_{\text{Delay}} = \sqrt{40^2 + 10^2 + 25^2} = \sqrt{2325} \approx 48.21825$
* $\text{Denom}_{\text{BER}} = \sqrt{(10^{-3})^2 + (10^{-5})^2 + (10^{-4})^2} = \sqrt{1.0101 \times 10^{-6}} \approx 0.00100504$

### Langkah 2: Matriks Ternormalisasi Berbobot ($v_{ij}$)
* $A_1$: $v_{11} = 0.5 \times (30 / 115.758) = 0.12958$, $v_{12} = 0.3 \times (40 / 48.218) = 0.24887$, $v_{13} = 0.2 \times (10^{-3} / 0.001005) = 0.19899$
* $A_2$: $v_{21} = 0.5 \times (100 / 115.758) = 0.43193$, $v_{22} = 0.3 \times (10 / 48.218) = 0.06222$, $v_{23} = 0.2 \times (10^{-5} / 0.001005) = 0.00199$
* $A_3$: $v_{31} = 0.5 \times (50 / 115.758) = 0.21597$, $v_{32} = 0.3 \times (25 / 48.218) = 0.15554$, $v_{33} = 0.2 \times (10^{-4} / 0.001005) = 0.01990$

### Langkah 3: Solusi Ideal
* $A^+ = [v_1^+ = \max, v_2^+ = \min, v_3^+ = \min] = [0.43193, 0.06222, 0.00199]$ (seluruhnya dimiliki oleh $A_2$)
* $A^- = [v_1^- = \min, v_2^- = \max, v_3^- = \max] = [0.12958, 0.24887, 0.19899]$ (seluruhnya dimiliki oleh $A_1$)

### Langkah 4: Jarak Euclidean & Skor Utilitas ($C_i$)
* Untuk $A_2$ (5G): $D_2^+ = 0.0$, $D_2^- = 0.39947 \implies C_2 = \frac{0.39947}{0.0 + 0.39947} = \mathbf{1.000000}$ (**Peringkat 1**)
* Untuk $A_3$ (WLAN): $D_3^+ = 0.23512$, $D_3^- = 0.21881 \implies C_3 = \frac{0.21881}{0.23512 + 0.21881} \approx \mathbf{0.482035}$ (**Peringkat 2**)
* Untuk $A_1$ (4G): $D_1^+ = 0.39947$, $D_1^- = 0.0 \implies C_1 = \frac{0.0}{0.39947 + 0.0} = \mathbf{0.000000}$ (**Peringkat 3**)

---

## 6. Format Input dan Output

### Input Format (`TopsisAlternative` / `NetworkSnapshot`)
```python
from wmc_simulator.baseline import TopsisAlternative, SingleTopsisUtilityFunction

alternatives = [
    TopsisAlternative("lte_1", {"data_rate_mbps": 25.0, "delay_ms": 40.0, "ber": 0.001}),
    TopsisAlternative("nr_1", {"data_rate_mbps": 150.0, "delay_ms": 10.0, "ber": 0.00001}),
    TopsisAlternative("wlan_1", {"data_rate_mbps": 60.0, "delay_ms": 20.0, "ber": 0.0001}),
]
```

### Output Format (`SingleTopsisResult`)
Objek hasil evaluasi memuat hasil audit lengkap:
* `best_alternative_id: str`: ID kandidat dengan skor utilitas tertinggi.
* `best_utility_score: float`: Nilai $C_i$ terbaik.
* `rankings: list[TopsisEvaluationResult]`: Daftar alternatif terurut lengkap dengan `rank`, `utility_score`, `d_plus`, dan `d_minus`.
* `details: TopsisStepDetail`: Matriks ternormalisasi, matriks terbobot, dan solusi ideal untuk verifikasi langkah demi langkah.

---

## 7. Kebijakan Penanganan Input Tidak Valid

| Kasus Input | Kebijakan Penanganan | Dampak Sistem |
|---|---|---|
| Alternatif kosong (`[]`) | Ditolak dengan `ValueError` | Mencegah evaluasi matriks kosong. |
| ID alternatif duplikat | Ditolak dengan `ValueError` | Menjamin integritas referensi kandidat. |
| Nilai kriteria `NaN` / `Infinity` / string | Ditolak dengan `ValueError` | Menjamin kestabilan kalkulasi numerik. |
| Bobot bernilai negatif / total 0 | Ditolak dengan `ValueError` | Menghindari anomali arah kriteria. |
| Bobot tidak sama dengan 1 | Dinormalisasi otomatis proporsional | Tetap berjalan adil tanpa error. |
| Kolom kriteria seluruhnya bernilai 0 | Ditetapkan $r_{ij} = 0.0$ | Tidak memicu `ZeroDivisionError`. |
| Seluruh alternatif identik | Ditetapkan $C_i = 0.5$ untuk semua | Menghindari pembagian $0 / (0 + 0)$. |
| Kandidat berstatus `available == False` | Disaring otomatis sebelum evaluasi | Alternatif luar jangkauan diabaikan. |

---

## 8. Keterbatasan dan Catatan Penelitian

1. **Perankingan Relatif**:
   Skor $C_i$ merepresentasikan kedekatan relatif di antara alternatif yang dievaluasi pada saat itu, bukan metrik absolut. Menambahkan atau menghapus satu alternatif dapat mengubah skor alternatif lain (*Rank Reversal Phenomenon*).
2. **Tanpa Mekanisme Histeresis Bawaan**:
   Single TOPSIS murni melakukan evaluasi pada setiap langkah waktu independen ($t$). Jika skor antara dua alternatif sangat berdekatan, perankingan dapat berganti-ganti secara cepat (*ping-pong handover*). Oleh karena itu, modul menyediakan metrik analisis `ping_pong_count` dan `ping_pong_rate` untuk mengevaluasi dampak ini.
