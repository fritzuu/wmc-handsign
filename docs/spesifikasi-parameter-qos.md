# Spesifikasi Parameter Input QoS Jaringan Heterogen (4G, 5G, WLAN)

Dokumen ini menetapkan spesifikasi, definisi operasional, rentang nilai, dasar ilmiah, dan format data untuk parameter masukan *Quality of Service* (QoS) pada jaringan heterogen (4G LTE, 5G NR, dan WLAN/Wi-Fi). Spesifikasi ini dirancang sebagai landasan ilmiah bagi:
1. Generator profil jaringan sintetis (`wmc_simulator.network.profile_generator`).
2. Evaluator baseline pembanding *Single TOPSIS Utility Function* (`wmc_simulator.baseline.topsis_utility`).
3. Sistem pengambil keputusan *Fuzzy-TOPSIS* (`lib/core/handover`).

---

## 1. Definisi Operasional Empat Parameter Utama

### 1.1. Received Signal Strength (RSS)
* **Satuan**: $\text{dBm}$ (*decibel-milliwatts*, skala logaritmik terhadap $1\text{ mW}$).
* **Arah Optimasi TOPSIS**: **Benefit** ($\max$) — nilai yang lebih besar (lebih mendekati 0 atau lebih positif) menandakan daya sinyal yang diterima lebih kuat.
* **Klarifikasi Esensial Metrik Fisik**:
  * **WLAN (Wi-Fi)**: Menggunakan **RSSI** (*Received Signal Strength Indicator*), yaitu pengukuran daya total pita lebar (seluruh kanal 20/40/80 MHz) yang diterima antena receiver, mencakup sinyal pembawa, interferensi ko-kanal/BSS sekitar, dan *thermal noise*.
  * **4G LTE**: Standard 3GPP (TS 36.133, TS 36.214) mendefinisikan **RSRP** (*Reference Signal Received Power*) sebagai daya rata-rata per *Resource Element* (RE) sinyal referensi seluler (subcarrier 15 kHz), bukan RSSI pita lebar. RSRP berkisar antara $-140\text{ dBm}$ hingga $-44\text{ dBm}$.
  * **5G NR**: Standard 3GPP (TS 38.133, TS 38.215) menggunakan **SS-RSRP** (*Synchronization Signal - RSRP*) dan **CSI-RSRP** (*Channel State Information - RSRP*).
  * **Catatan Komparasi Heterogen**: Di dalam simulasi/TOPSIS, nama field diabstraksikan sebagai `rss_dbm`. Namun secara fisik, $-75\text{ dBm}$ RSRP pada LTE/NR merepresentasikan kualitas kanal yang jauh lebih superior dibandingkan $-75\text{ dBm}$ RSSI pada Wi-Fi karena RSRP diukur pada pita sempit subcarrier (daya terkonsentrasi). Normalisasi vektor TOPSIS dan normalisasi rentang lokal per teknologi menjaga keadilan pemeringkatan ini.

### 1.2. Data Rate (Throughput Efektif)
* **Satuan**: $\text{Mbps}$ (*Megabits per second*).
* **Arah Optimasi TOPSIS**: **Benefit** ($\max$) — semakin tinggi kecepatan transfer data, semakin baik kualitas layanan.
* **Definisi Operasional**:
  * Nilai yang digunakan adalah **Achievable User-Experienced Downlink Throughput** (kecepatan transfer data riil yang dapat diterima lapisan transport/aplikasi pengguna), **bukan** *Theoretical Peak Physical Layer Burst Rate*.
  * Throughput efektif memperhitungkan *overhead* protokol (MAC/IP headers), penyesuaian adaptasi modulasi dan pengkodean (*Modulation and Coding Scheme / MCS*), serta utilisasi kanal.

### 1.3. Delay (Latensi)
* **Satuan**: $\text{ms}$ (*milliseconds*).
* **Arah Optimasi TOPSIS**: **Cost** ($\min$) — semakin rendah latensi, semakin responsif layanan.
* **Definisi Operasional**:
  * Pengukuran didefinisikan sebagai **One-Way Latency pada Radio Access Network (User Plane RAN Latency)** ditambah waktu antrean transmisi paket (*queuing delay*).
  * **Perhatian Konsistensi**: Spesifikasi ini **tidak mencampuradukkan One-Way Delay (OWD) dengan Round-Trip Time (RTT)**. Jika sistem pengukuran lapangan menggunakan pengujian RTT (seperti ICMP ping atau socket round-trip), nilai RTT harus dikonversi dengan pendekatan simetris $\text{OWD} \approx \text{RTT} / 2$ sebelum dievaluasi terhadap rentang OWD.

### 1.4. Bit Error Rate (BER)
* **Satuan**: Rasio murni tak berdimensi (*dimensionless ratio*), dinotasikan sebagai float dalam rentang $[0.0, 1.0]$ atau notasi ilmiah (misal $1.0 \times 10^{-6}$).
* **Arah Optimasi TOPSIS**: **Cost** ($\min$) — semakin rendah rasio bit salah, semakin andal integritas transmisi data.
* **Definisi Operasional**:
  * Rasio jumlah bit yang diterima salah (*corrupted bits*) terhadap total bit yang ditransmisikan setelah proses pengkodean kanal (*post-Forward Error Correction / residual BER*):
    $$\text{BER} = \frac{N_{\text{error}}}{N_{\text{total}}}$$
* **Penanganan Nilai Nol & Skala Logaritmik**:
  * Jika saluran transmisi sempurna dan tidak ditemukan bit salah dalam jendela observasi, nilai BER secara matematis bernilai `0.0`.
  * Dalam matriks TOPSIS, nilai `0.0` valid dan ditangani secara aman tanpa pembagian nol.
  * Namun, untuk generator yang menggunakan interpolasi berbasis logaritmik ($\log_{10}(\text{BER})$), ditetapkan nilai lantai numerik (*floor threshold*) sebesar $\text{BER}_{\text{floor}} = 1.0 \times 10^{-9}$ guna menghindari $\log_{10}(0) = -\infty$.

---

## 2. Karakterisasi Teknologi Jaringan

### 2.1. 4G LTE (Long Term Evolution)
* **Spesifikasi Acuan**: 3GPP Release 8–12, UE Category 4/6, lebar pita $20\text{ MHz}$ FDD/TDD, konfigurasi $2\times 2$ MIMO.
* **Karakteristik**: Makro-seluler jangkauan luas (radius hingga 1–2 km), koordinasi alokasi spektrum terpusat (OFDMA downlink / SC-FDMA uplink).

### 2.2. 5G NR (New Radio)
* **Spesifikasi Acuan**: 3GPP Release 15–16, Standalone/Non-Standalone Sub-6 GHz (Frequency Range 1 / FR1, misal pita n78 $3.5\text{ GHz}$), lebar pita $100\text{ MHz}$ TDD, *Subcarrier Spacing* $30\text{ kHz}$ ($\mu = 1$), konfigurasi $4\times 4$ MIMO.
* **Karakteristik**: Jangkauan menengah-pendek (radius 300–500 meter), throughput sangat tinggi, latensi radio rendah (*mini-slot scheduling*).

### 2.3. WLAN / Wi-Fi
* **Penetapan Versi Spesifik**: Ditetapkan secara eksplisit sebagai **Wi-Fi 5 (IEEE 802.11ac Wave 2)** dan **Wi-Fi 6 (IEEE 802.11ax)** pada pita frekuensi $5\text{ GHz}$, lebar kanal $80\text{ MHz}$, konfigurasi $2\times 2$ MIMO.
* **Alasan Penetapan Versi**:
  * Istilah "WLAN" tidak boleh dianggap merujuk pada standar tunggal (seperti 802.11b kuno).
  * 802.11ac/ax pada 5 GHz dipilih karena merupakan standar de facto yang paling banyak digunakan oleh perangkat *smartphone* modern dan *Access Point* komersial yang bersaing langsung dengan 4G/5G di area perkantoran/perkotaan.
* **Karakteristik**: Sel mikro jangkauan terbatas (radius 50–100 meter), berbasis mekanisme akses acak *Carrier Sense Multiple Access with Collision Avoidance* (CSMA/CA).

---

## 3. Tabel Spesifikasi Komparatif Parameter QoS

Tabel berikut menyajikan rentang operasional simulasi yang diusulkan, pemisahan antara standar resmi dan asumsi eksperimen, serta justifikasinya:

| Parameter | Teknologi | Rentang yang Diusulkan | Satuan | Standar / Sumber Acuan | Tipe Nilai | Justifikasi Ilmiah & Alasan Pemilihan |
|---|---|---|---|---|---|---|
| **RSS** | **4G LTE** | $[-120.0, -50.0]$ | dBm | 3GPP TS 36.133 Table 9.1.2-1; ITU-R M.2134 | Batas Standar & Operasional | $-120\text{ dBm}$ adalah ambang batas sensitivitas RSRP seluler minimum untuk *cell edge handover*; $-50\text{ dBm}$ adalah batas saturasi daya penerima di dekat eNodeB. |
| | **5G NR** | $[-110.0, -40.0]$ | dBm | 3GPP TS 38.133 Table 10.1.2-1; ITU-R M.2410 | Batas Standar & Operasional | Propagasi frekuensi tinggi FR1 ($3.5\text{ GHz}$) memiliki redaman lebih besar di batas sel ($-110\text{ dBm}$), dan daya penerimaan dekat gNodeB mencapai $-40\text{ dBm}$. |
| | **WLAN** | $[-90.0, -30.0]$ | dBm | IEEE Std 802.11-2020; Cisco Enterprise Wireless Guidelines | Praktik Industri | $-90\text{ dBm}$ adalah batas modulasi terendah (BPSK 1/2) sebelum *disconnection*; $-30\text{ dBm}$ adalah kondisi *line-of-sight* (LOS) berjarak 1 meter dari AP. |
| **Data Rate** | **4G LTE** | $[1.0, 100.0]$ | Mbps | 3GPP TS 36.306 Cat 4/6; OpenSignal Mobile Report | Asumsi Terkalibrasi Standar | Teoretis peak Cat 4 adalah 150 Mbps, namun *achievable throughput* nyata di cell-edge berkisar 1 Mbps dan kondisi optimal berkisar 80–100 Mbps. |
| | **5G NR** | $[50.0, 1000.0]$ | Mbps | ITU-R M.2410-0 (IMT-2020 eMBB); 3GPP TR 38.913 | Batas Standar IMT-2020 | Target IMT-2020 mensyaratkan user-experienced data rate 100 Mbps (50 Mbps pada beban tinggi) hingga 1 Gbps (1000 Mbps) pada saluran 100 MHz 256-QAM. |
| | **WLAN** | $[1.0, 600.0]$ | Mbps | IEEE 802.11ac/ax Specification; Wi-Fi Alliance | Praktik Industri Terkalibrasi | Peak PHY 80 MHz 2x2 MIMO adalah 867–1201 Mbps, tetapi throughput lapisan transport bersih dengan *CSMA/CA overhead* berkisar 1 Mbps (ramai/jauh) hingga 600 Mbps (sepi/dekat). |
| **Delay** | **4G LTE** | $[10.0, 100.0]$ | ms | 3GPP TR 36.912 Sec 13.1; ITU-R M.2134 | Batas Standar & Lapangan | Spesifikasi RAN user-plane latency ideal adalah $< 5\text{ ms}$, namun latensi nyata termasuk antrean jaringan inti dan retransmisi HARQ berkisar 10–100 ms. |
| | **5G NR** | $[1.0, 20.0]$ | ms | 3GPP TS 38.300; ITU-R M.2410-0 URLLC/eMBB | Batas Standar IMT-2020 | Target latensi antarmuka radio 5G adalah 4 ms untuk eMBB dan 1 ms untuk URLLC; rentang 1–20 ms mencakup latensi propagasi dan jitter penjadwalan. |
| | **WLAN** | $[5.0, 50.0]$ | ms | IEEE 802.11-2020 EDCA QoS; ITU-T G.1050 | Praktik Industri | Akses kanal tanpa kompetisi mencapai 5 ms; kompetisi kanal padat dan retransmisi MAC meningkatkan delay hingga 50 ms. |
| **BER** | **4G LTE** | $[10^{-6}, 10^{-3}]$ | rasio | 3GPP TS 36.212; 3GPP TS 36.213 (BLER 10%) | Rekayasa Kanal | Target Block Error Rate (BLER) 4G adalah 10% ($10^{-1}$), yang setelah dikoreksi Turbo decoder menghasilkan residual BER $10^{-6}$ (bagus) hingga $10^{-3}$ (kritis). |
| | **5G NR** | $[10^{-8}, 10^{-5}]$ | rasio | 3GPP TS 38.212 (LDPC / Polar Codes) | Rekayasa Kanal | Penggunaan kode LDPC canggih pada kanal data eMBB menghasilkan residual bit error yang jauh lebih rendah ($10^{-8}$ hingga $10^{-5}$). |
| | **WLAN** | $[10^{-7}, 10^{-4}]$ | rasio | IEEE 802.11ac/ax BCC/LDPC PHY Specifications | Rekayasa Kanal | Standard 802.11 mensyaratkan packet error rate (PER) $< 10\%$, berkorespondensi dengan rentang bit error pasca-Viterbi/LDPC $10^{-7}$ hingga $10^{-4}$. |

---

## 4. Faktor-Faktor Fisik yang Memengaruhi Nilai QoS

Nilai parameter QoS yang dimodelkan oleh generator dipengaruhi oleh faktor kanal propagasi dan lingkungan:

1. **Jarak Propagasi & Path Loss**:
   Daya terima berkurang seiring bertambahnya jarak $d$ mengikuti *Log-Distance Path Loss Model*:
   $$PL(d) = PL(d_0) + 10 \cdot n \cdot \log_{10}\left(\frac{d}{d_0}\right) + X_\sigma$$
   di mana $n$ adalah eksponen path loss ($n = 2.0$ ruang bebas, $n = 3.0 - 4.0$ lingkungan urban/indoor), dan $d_0 = 1\text{ meter}$.
2. **Shadow Fading (Obstruksi Bangunan/Dinding)**:
   Variasi acak skala besar dimodelkan sebagai variabel acak Gaussian $X_\sigma \sim \mathcal{N}(0, \sigma^2)$ dengan standar deviasi $\sigma = 4.0 - 8.0\text{ dB}$.
3. **Interferensi dan Beban Pengguna (Congestion)**:
   Pada Wi-Fi, mekanisme CSMA/CA menyebabkan degradasi throughput eksponensial saat banyak perangkat aktif di kanal yang sama. Pada seluler, interferensi ko-kanal dari *neighbor cell* menurunkan SINR (*Signal-to-Interference-plus-Noise Ratio*).
4. **Kecepatan Pengguna & Efek Doppler**:
   Pergerakan cepat pengguna ($v > 15\text{ m/s}$) menyebabkan pergeseran frekuensi Doppler $f_d = \frac{v \cdot f_c}{c}$, menurunkan waktu koherensi kanal, meningkatkan frekuensi *handover*, dan menaikkan BER.
5. **Karakteristik Frekuensi Spektrum**:
   Frekuensi 5G ($3.5\text{ GHz}$) dan Wi-Fi ($5\text{ GHz}$) memiliki daya tembus dinding (*penetration loss*) yang jauh lebih rendah dibandingkan pita seluler 4G ($800 - 1800\text{ MHz}$). Akibatnya, di dalam ruangan yang jauh dari AP, 4G sering kali memberikan stabilitas sinyal yang lebih baik daripada 5G atau Wi-Fi.

---

## 5. Hubungan dengan Modul TOPSIS dan Pembobotan Kriteria

Dalam evaluasi Single TOPSIS maupun Fuzzy-TOPSIS, kriteria QoS dinormalisasi secara vektor untuk menghilangkan perbedaan satuan:

$$r_{ij} = \frac{x_{ij}}{\sqrt{\sum_{k=1}^m x_{kj}^2}}$$

### 5.1. Matriks Arah Optimasi
* $C_1$: **Data Rate** $\to$ **Benefit** ($v_1^+ = \max, v_1^- = \min$)
* $C_2$: **Delay** $\to$ **Cost** ($v_2^+ = \min, v_2^- = \max$)
* $C_3$: **BER** $\to$ **Cost** ($v_3^+ = \min, v_3^- = \max$)
* $C_4$ *(jika disertakan)*: **RSS** $\to$ **Benefit** ($v_4^+ = \max, v_4^- = \min$)

### 5.2. Profil Bobot Berdasarkan Kelas Aplikasi
Sesuai rancangan AHP pada literatur (Ndegwa et al., 2023) dan PRD v2.0 (FR-07):
* **Conversational (Suara / Video Call)**: Memprioritaskan latensi rendah ($w_{\text{delay}} = 0.50$, $w_{\text{ber}} = 0.30$, $w_{\text{rate}} = 0.20$).
* **Streaming (Video On Demand)**: Memprioritaskan throughput tinggi ($w_{\text{rate}} = 0.50$, $w_{\text{delay}} = 0.30$, $w_{\text{ber}} = 0.20$).
* **Interactive (Web / Gaming)**: Memprioritaskan latensi dan throughput seimbang ($w_{\text{rate}} = 0.40$, $w_{\text{delay}} = 0.35$, $w_{\text{ber}} = 0.25$).
* **Background (Download / Sync)**: Memprioritaskan throughput murni ($w_{\text{rate}} = 0.60$, $w_{\text{delay}} = 0.20$, $w_{\text{ber}} = 0.20$).

---

## 6. Asumsi Simulasi dan Keterbatasannya

1. **Bukan Pengganti Field Test**: Data yang dihasilkan oleh model generator adalah data sintetis berbasis model propagasi teoretis. Hasil pengujian algoritma pada simulator tidak boleh diklaim sebagai performa absolut lapangan sebelum divalidasi dengan *Walk Test* nyata.
2. **5G Tidak Selalu Lebih Baik**: Skenario simulasi tidak boleh mengasumsikan 5G selalu menang. Jika pengguna berada di luar radius efektif 5G ($> 300\text{ m}$), redaman tinggi akan menurunkan RSS dan data rate 5G di bawah 4G atau Wi-Fi lokal.
3. **Ketersediaan Jaringan (Availability Gating)**: Kandidat jaringan dinyatakan *unavailable* (`available: false`) jika nilai RSS berada di bawah ambang sensitivitas minimum ($\text{RSS} < \text{RSS}_{min}$). Kandidat yang *unavailable* otomatis dikeluarkan dari perankingan TOPSIS.

---

## 7. Skema Konfigurasi Terstruktur untuk Generator (JSON Schema)

Format JSON terstruktur berikut mendefinisikan kontrak parameter yang kompatibel dengan generator Python dan modul Dart:

```json
{
  "qos_profiles": {
    "4G": {
      "technology": "4G",
      "rss_dbm": { "min": -120.0, "max": -50.0, "unit": "dBm", "direction": "benefit" },
      "data_rate_mbps": { "min": 1.0, "max": 100.0, "unit": "Mbps", "direction": "benefit" },
      "delay_ms": { "min": 10.0, "max": 100.0, "unit": "ms", "direction": "cost" },
      "ber": { "min": 1e-6, "max": 1e-3, "unit": "ratio", "direction": "cost", "floor": 1e-9 },
      "coverage_radius_m": 1000.0
    },
    "5G": {
      "technology": "5G",
      "rss_dbm": { "min": -110.0, "max": -40.0, "unit": "dBm", "direction": "benefit" },
      "data_rate_mbps": { "min": 50.0, "max": 1000.0, "unit": "Mbps", "direction": "benefit" },
      "delay_ms": { "min": 1.0, "max": 20.0, "unit": "ms", "direction": "cost" },
      "ber": { "min": 1e-8, "max": 1e-5, "unit": "ratio", "direction": "cost", "floor": 1e-9 },
      "coverage_radius_m": 500.0
    },
    "WLAN": {
      "technology": "WLAN",
      "standard_version": "IEEE 802.11ac/ax 5GHz 80MHz",
      "rss_dbm": { "min": -90.0, "max": -30.0, "unit": "dBm", "direction": "benefit" },
      "data_rate_mbps": { "min": 1.0, "max": 600.0, "unit": "Mbps", "direction": "benefit" },
      "delay_ms": { "min": 5.0, "max": 50.0, "unit": "ms", "direction": "cost" },
      "ber": { "min": 1e-7, "max": 1e-4, "unit": "ratio", "direction": "cost", "floor": 1e-9 },
      "coverage_radius_m": 100.0
    }
  }
}
```

---

## 8. Rekomendasi Checklist Pengujian Konsistensi Input TOPSIS

Sebelum matriks keputusan diproses oleh algoritma Single TOPSIS, lakukan validasi input:
- [x] **Finite Check**: Semua angka harus berupa bilangan riil hingga (`isfinite() == true`), tidak boleh `NaN` atau `Infinity`.
- [x] **Boundary Check**:
  - $\text{Data Rate} \ge 0.0\text{ Mbps}$
  - $\text{Delay} \ge 0.0\text{ ms}$
  - $0.0 \le \text{BER} \le 1.0$ (disimpan sebagai rasio, bukan persentase)
- [x] **Availability Filter**: Hanya jaringan dengan `available == true` yang dimasukkan ke dalam matriks keputusan TOPSIS.
- [x] **Direction Consistency**: Pastikan arah kriteria selalu konsisten: Data Rate (Benefit), Delay (Cost), BER (Cost).
- [x] **Weights Normalization**: Pastikan total bobot kriteria yang dimasukkan bernilai positif dan dinormalisasi menjadi $\sum w_j = 1.0$.

---

## 9. Referensi Standar & Ilmiah yang Dapat Diverifikasi

1. **3GPP TS 36.133**: *E-UTRA; Requirements for support of radio resource management*, v15.4.0, 3rd Generation Partnership Project.
2. **3GPP TS 38.133**: *NR; Requirements for support of radio resource management*, v16.3.0, 3rd Generation Partnership Project.
3. **3GPP TS 36.300 / TS 38.300**: *Overall description; Stage 2 (LTE and 5G NR architecture and radio protocols)*.
4. **ITU-R Report M.2134 (2008)**: *Requirements related to technical performance for IMT-Advanced radio interface(s)*, International Telecommunication Union.
5. **ITU-R Report M.2410-0 (2017)**: *Minimum requirements related to technical performance for IMT-2020 radio interface(s)*, International Telecommunication Union.
6. **IEEE Std 802.11-2020**: *IEEE Standard for Information Technology—Telecommunications and Information Exchange between Systems—Local and Metropolitan Area Networks—Specific Requirements - Part 11: Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications*.
7. **S. Ndegwa, K. Nyachionjeka, E. T. Mharakurwa (2023)**: *"User Preference-Based Heterogeneous Network Management System for Vertical Handover"*, Journal of Electrical and Computer Engineering / Journal of Sustainable Research in Engineering.
8. **M. Al-bashiri et al. (2018)**: *"A decision-making framework for vertical handover in heterogeneous wireless networks"*, PLOS ONE, doi:10.1371/journal.pone.0204434.
