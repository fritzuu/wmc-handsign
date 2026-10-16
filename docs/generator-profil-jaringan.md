# Dokumentasi Generator Profil Jaringan Heterogen (4G LTE, 5G NR, WLAN)

Dokumen ini menjelaskan rancangan, pemodelan matematis, konfigurasi, integrasi, dan petunjuk penggunaan modul **Generator Profil Jaringan Heterogen** (`wmc_simulator.network.profile_generator`).

---

## 1. Tujuan Modul

Modul generator profil jaringan heterogen dikembangkan untuk:
1. **Mensintesis Parameter QoS Realistis**: Menghasilkan empat parameter utama (RSS, Data Rate, Delay, BER) untuk teknologi 4G LTE, 5G NR, dan WLAN/Wi-Fi berdasarkan rentang fisik dan kondisi operasional jaringan (*good*, *moderate*, *poor*).
2. **Menyediakan Data Sintetis Terkontrol**: Sebagai substitusi data empiris ketika data pengukuran lapangan (*walk test*) belum tersedia, untuk mengevaluasi kinerja algoritma pemilihan jaringan (*vertical handover*).
3. **Pengujian Algoritma Seleksi Jaringan**: Mendukung evaluasi baseline *Single TOPSIS Utility Function* serta algoritma primer *Adaptive Fuzzy-TOPSIS*.
4. **Pembangkitan Skenario Temporal & Mobilitas**: Mendukung variasi deret waktu berkorelasi halus (*auto-regressive fading drift*) dan integrasi pergerakan pengguna berbasis *Random Waypoint Model*.

---

## 2. Struktur Data dan Format Output

Generator menghasilkan objek profil berkontrak ketat `NetworkProfile` yang dapat diekspor langsung ke format JSON terstandar:

```json
{
  "profile_id": "profile_4g_sample",
  "technology": "4G",
  "condition": "good",
  "timestamp": 0.0,
  "parameters": {
    "rss_dbm": -66.52,
    "data_rate_mbps": 63.88,
    "delay_ms": 26.54,
    "ber": 3.41e-06
  },
  "available": true,
  "metadata": {
    "data_source": "synthetic",
    "model_version": "1.0",
    "metric_type": "RSRP",
    "quality_factor": 0.7676,
    "network_load": 0.5
  }
}
```

### Kamus Data Parameter:
| Field | Tipe | Satuan | Deskripsi |
|---|---|---|---|
| `profile_id` | `string` | - | Pengenal unik kandidat profil. |
| `technology` | `string` | - | Jenis teknologi: `"4G"`, `"5G"`, atau `"WLAN"`. |
| `condition` | `string` | - | Kategori kondisi: `"good"`, `"moderate"`, `"poor"`, atau `"random"`. |
| `timestamp` | `float` | detik | Titik waktu observasi simulasi. |
| `rss_dbm` | `float` | $\text{dBm}$ | Daya sinyal terima (RSRP untuk seluler, RSSI untuk Wi-Fi). |
| `data_rate_mbps` | `float` | $\text{Mbps}$ | Kecepatan data hilir efektif (*achievable user throughput*). |
| `delay_ms` | `float` | $\text{ms}$ | Latensi transmisi satu arah (*one-way delay*) + antrean. |
| `ber` | `float` | rasio $[0, 1]$ | Rasio bit salah pasca koreksi galat (*post-FEC residual BER*). |
| `available` | `boolean` | - | Status ketersediaan jaringan ($\text{True}$ jika sinyal mencukupi). |

---

## 3. Model Pembangkitan Data & Hubungan Antarparameter

Generator mengimplementasikan model hibrida: **pendekatan berbasis rentang kondisi** dan **pemodelan hubungan fisis antarparameter**:

### 3.1. Faktor Kualitas Sinyal ($\rho$) per Kondisi
Kondisi operasional diabstraksikan menjadi faktor kualitas kontinu $\rho \in [0, 1]$ yang disampel menggunakan distribusi segitiga (*triangular distribution*):
* **Kondisi Baik (`good`)**: $\rho \sim \text{Triangular}(0.65, 0.98, 0.85)$ (sinyal kuat, kanal bersih).
* **Kondisi Sedang (`moderate`)**: $\rho \sim \text{Triangular}(0.35, 0.75, 0.55)$ (sinyal rata-rata perkotaan).
* **Kondisi Buruk (`poor`)**: $\rho \sim \text{Triangular}(0.05, 0.40, 0.20)$ (batas sel / banyak obstruksi).

### 3.2. Formulasi Penurunan Parameter dari $\rho$
1. **Received Signal Strength (RSS)**:
   $$\text{RSS} = \text{RSS}_{\min} + \rho \cdot (\text{RSS}_{\max} - \text{RSS}_{\min}) + X_{\sigma}$$
   dengan residual bayangan Gaussian $X_{\sigma} \sim \mathcal{N}(0, 1.0\text{ dB})$.
2. **Data Rate ($R$)**:
   Dimodelkan mengikuti adaptasi modulasi non-linear Shannon/MCS ($\rho^{1.5}$) yang terdegradasi oleh beban antrean (*network load* $L \in [0, 1]$):
   $$R = R_{\min} + (R_{\max} - R_{\min}) \cdot \rho^{1.5} \cdot (1.0 - 0.25 \cdot L) + \epsilon_{\text{rate}}$$
3. **Delay ($D$)**:
   Meningkat drastis pada sinyal lemah akibat retransmisi MAC/HARQ dan memanjang akibat beban antrean:
   $$D = D_{\min} + (D_{\max} - D_{\min}) \cdot (1.0 - \rho)^{1.2} \cdot (1.0 + 0.40 \cdot L) + \epsilon_{\text{delay}}$$
4. **Bit Error Rate ($\text{BER}$)**:
   Berbanding terbalik pada skala logaritmik terhadap kualitas kanal:
   $$\log_{10}(\text{BER}) = \log_{10}(\text{BER}_{\max}) + (1.0 - \rho) \cdot (\log_{10}(\text{BER}_{\min}) - \log_{10}(\text{BER}_{\max})) + \epsilon_{\text{ber}}$$
   $$\text{BER} = 10^{\log_{10}(\text{BER})}, \quad \text{dibatasi minimal } 1.0 \times 10^{-9}.$$

### 3.3. Pemodelan Fluktuasi Temporal (AR(1) Drift)
Untuk simulasi temporal beruntun, kualitas kanal pada langkah waktu berikutnya mengalami *auto-regressive drift*:
$$\rho_{t+1} = \alpha \cdot \rho_t + (1 - \alpha) \cdot \mu_{\text{condition}} + \sigma \cdot \epsilon$$
Koefisien korelasi $\alpha = 0.85$ menjamin fluktuasi parameter berlangsung mulus (merefleksikan *shadow fading* temporal) tanpa lonjakan ekstrem yang tidak realistis.

---

## 4. Perbedaan Profil Antarteknologi (4G vs 5G vs WLAN)

| Parameter | 4G LTE | 5G NR | WLAN (Wi-Fi 5/6) |
|---|---|---|---|
| **Metrik Sinyal** | RSRP (Narrowband 15 kHz) | SS-RSRP (Subcarrier 30 kHz) | RSSI (Broadband 80 MHz) |
| **Rentang RSS** | $[-120, -50]\text{ dBm}$ | $[-110, -40]\text{ dBm}$ | $[-90, -30]\text{ dBm}$ |
| **Rentang Throughput** | $[1, 100]\text{ Mbps}$ | $[50, 1000]\text{ Mbps}$ | $[1, 600]\text{ Mbps}$ |
| **Rentang Latensi** | $[10, 100]\text{ ms}$ | $[1, 20]\text{ ms}$ | $[5, 50]\text{ ms}$ |
| **Rentang BER** | $[10^{-6}, 10^{-3}]$ | $[10^{-8}, 10^{-5}]$ | $[10^{-7}, 10^{-4}]$ |
| **Radius Cakupan** | $1000\text{ meter}$ | $500\text{ meter}$ | $100\text{ meter}$ |

---

## 5. Cara Mengonfigurasi dan Menjalankan Generator

### 5.1. Pembangkitan Profil Tunggal
```python
from wmc_simulator.network import HeterogeneousProfileGenerator

generator = HeterogeneousProfileGenerator(seed=42)

# Bangkitkan profil 5G dalam kondisi baik
profile = generator.generate_profile(
    technology="5G",
    condition="good",
    profile_id="nr_node_01",
    timestamp_s=0.0,
    network_load=0.3,
)

print(profile.to_dict())
```

### 5.2. Pembangkitan Batch Multi-Teknologi
```python
# Bangkitkan 15 profil campuran (good, moderate, poor)
batch = generator.generate_batch(
    count=15,
    technologies=("4G", "5G", "WLAN"),
    condition="mixed",
    id_prefix="scenario_node",
)
```

### 5.3. Pembangkitan Deret Waktu (Temporal Sequence)
```python
# Bangkitkan deret waktu 10 detik dengan interval dt = 1.0s
sequence = generator.generate_temporal_sequence(
    technology="4G",
    num_steps=10,
    dt_s=1.0,
    condition="moderate",
    correlation=0.85,
)
```

### 5.4. Integrasi Langsung dengan Modul TOPSIS
```python
from wmc_simulator.baseline.topsis_utility import (
    SingleTopsisUtilityFunction,
    TopsisAlternative,
)

# Konversi NetworkProfile ke NetworkSnapshot lalu TopsisAlternative
alternatives = [
    TopsisAlternative.from_network_snapshot(p.to_network_snapshot())
    for p in batch[:3]
]

topsis = SingleTopsisUtilityFunction()
result = topsis.evaluate(alternatives)
print(f"Pemenang Handover: {result.best_alternative_id}")
```

### 5.5. Menjalankan Demo Interaktif
Jalankan skrip demo bawaan di terminal:
```bash
python demo_heterogeneous_generator.py
```

---

## 6. Cara Menjalankan Pengujian

Jalankan rangkaian pengujian otomatis menggunakan modul `unittest`:
```bash
# Uji khusus generator profil heterogen
python -m unittest tests/test_heterogeneous_profile_generator.py -v

# Uji seluruh rangkaian simulator (61 tes)
python -m unittest discover -s tests -v
```

---

## 7. Keterbatasan Data Sintetis vs Pengukuran Nyata

1. **Bukan Data Hasil Pengukuran Hardware**:
   Data yang dihasilkan merupakan data sintetis berbasis pemodelan teoritis propagasi dan distribusi stokastik terkalibrasi standar. Hasil evaluasi tidak boleh dianggap sebagai hasil *drive test* atau *walk test* modem fisik sebelum diverifikasi di lapangan.
2. **Variasi Lingkungan yang Disederhanakan**:
   Model belum mencakup topologi 3D gedung bertingkat atau pemodelan antena array *beamforming* multi-elemen adaptif (Massive MIMO).
3. **Pemisahan Trafik Discrete vs Kontinu**:
   Beban jaringan dimodelkan sebagai faktor kontinu $[0, 1]$, bukan antrean paket antarmuka *packet-level discrete-event* (seperti ns-3 atau OMNeT++).
