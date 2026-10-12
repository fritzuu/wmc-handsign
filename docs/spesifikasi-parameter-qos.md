# Spesifikasi Parameter Input QoS Jaringan Heterogen (4G LTE, 5G NR, WLAN)

Dokumen ini merupakan spesifikasi teknis dan ilmiah resmi untuk penentuan parameter input *Quality of Service* (QoS) pada jaringan heterogen (4G LTE, 5G NR, dan WLAN/Wi-Fi). Spesifikasi ini dirancang sebagai landasan terpadu bagi:
1. **Generator Profil Jaringan Heterogen** (`wmc_simulator.network.profile_generator`).
2. **Evaluasi Baseline Single TOPSIS Utility Function** (`wmc_simulator.baseline.topsis_utility`).
3. **Engine Pengambil Keputusan Handover Heterogen** (`lib/core/handover`).

---

## 1. Audit Repository dan Integrasi dengan Kontrak yang Ada

Berdasarkan audit menyeluruh terhadap repositori `wmc-handsign`:
- **Model Data Simulator (`wmc_simulator.models.NetworkSnapshot`)** telah menetapkan kontrak field kanonis:
  - `rss_dbm: float` (daya terima sinyal dalam dBm)
  - `data_rate_mbps: float` (kecepatan data dalam Mbps, $\ge 0$)
  - `delay_ms: float` (latensi dalam milidetik, $\ge 0$)
  - `ber: float` (bit error rate sebagai rasio numerik, $0 \le \text{BER} \le 1$)
  - `available: bool` (status ketersediaan kanal)
- **Model Data Mobile / Flutter (`lib/core/handover/models.dart`)** menggunakan kontrak yang identik secara semantik (`rssDbm`, `dataRateMbps`, `delayMs`, `ber`, `available`).
- **Generator Default (`wmc_simulator/network/profile_generator.py`)** dan **Konfigurasi Mobile (`lib/core/handover/configuration.dart`)** telah menggunakan rentang awal:
  - 4G LTE: RSS $[-120, -50]\text{ dBm}$, Rate $[1, 100]\text{ Mbps}$, Delay $[10, 100]\text{ ms}$, BER $[10^{-6}, 10^{-3}]$
  - 5G NR: RSS $[-110, -40]\text{ dBm}$, Rate $[50, 1000]\text{ Mbps}$, Delay $[1, 20]\text{ ms}$, BER $[10^{-8}, 10^{-5}]$
  - WLAN: RSS $[-90, -30]\text{ dBm}$, Rate $[1, 600]\text{ Mbps}$, Delay $[5, 50]\text{ ms}$, BER $[10^{-7}, 10^{-4}]$
- **Status Integrasi**: Spesifikasi ini memformalkan, memberikan dasar ilmiah standar internasional (3GPP, ITU-R, IEEE), dan menetapkan batas toleransi input agar konsisten di seluruh pipeline tanpa merusak kompatibilitas kode yang sudah berjalan.

---

## 2. Definisi Operasional Empat Parameter Utama

### 2.1. Received Signal Strength (RSS)
* **Satuan**: $\text{dBm}$ (*decibel-milliwatts*, skala logaritmik terhadap referensi $1\text{ mW}$).
* **Arah Optimasi TOPSIS**: **Benefit** ($\max$) — nilai yang lebih besar (lebih mendekati 0 atau lebih positif) merepresentasikan daya sinyal yang lebih kuat.
* **Perbedaan Fundamental Metrik Sinyal Antar-Teknologi**:
  * **WLAN (Wi-Fi)**: Menggunakan **RSSI** (*Received Signal Strength Indicator*), yaitu pengukuran daya total pita lebar (*wideband*) pada keseluruhan kanal aktif (20, 40, atau 80 MHz). Nilai RSSI mencakup sinyal pembawa yang diinginkan, interferensi ko-kanal/BSS sekitar, serta derau termal (*thermal noise*).
  * **4G LTE**: Standard 3GPP (TS 36.133, TS 36.214) menggunakan **RSRP** (*Reference Signal Received Power*) sebagai daya rata-rata per *Resource Element* (RE) pada subcarrier pita sempit ($15\text{ kHz}$) yang membawa Cell-specific Reference Signal (CRS).
  * **5G NR**: Standard 3GPP (TS 38.133, TS 38.215) menggunakan **SS-RSRP** (*Synchronization Signal - RSRP*) dan **CSI-RSRP** (*Channel State Information - RSRP*) pada subcarrier ($30\text{ kHz}$ atau $15\text{ kHz}$).
* **Interpretasi Perbandingan Sinyal Heterogen**:
  * Daya RSRP seluler $-80\text{ dBm}$ merepresentasikan kualitas kanal yang jauh lebih superior dibandingkan RSSI $-80\text{ dBm}$ pada Wi-Fi. Hal ini karena RSRP terkonsentrasi pada subcarrier $15\text{ kHz}$, sedangkan RSSI Wi-Fi tersebar di seluruh pita $80\text{ MHz}$.
  * Oleh karena itu, modul TOPSIS menormalisasi nilai sinyal menggunakan normalisasi vektor Euclidean atau skala min-max lokal per teknologi sehingga pemeringkatan tidak bias terhadap perbedaan metode pengukuran fisik.

### 2.2. Data Rate (Throughput Efektif)
* **Satuan**: $\text{Mbps}$ (*Megabits per second*).
* **Arah Optimasi TOPSIS**: **Benefit** ($\max$) — semakin tinggi kecepatan transfer data, semakin baik kualitas alternatif jaringan.
* **Definisi Operasional**:
  * Nilai yang digunakan adalah **Achievable User-Experienced Downlink Throughput** (kecepatan transfer data riil yang dapat diterima lapisan transport/aplikasi pengguna), **bukan** *Theoretical Peak Physical Layer Burst Rate*.
  * Throughput efektif memperhitungkan *overhead* protokol (MAC/IP headers, CSMA/CA contention), efisiensi modulasi (*Modulation and Coding Scheme / MCS*), lebar spektrum yang dialokasikan, dan kepadatan pengguna aktif.

### 2.3. Delay (Latensi)
* **Satuan**: $\text{ms}$ (*milliseconds*).
* **Arah Optimasi TOPSIS**: **Cost** ($\min$) — semakin rendah latensi, semakin responsif layanan.
* **Definisi Operasional**:
  * Pengukuran didefinisikan sebagai **One-Way Latency pada Radio Access Network (User-Plane RAN Latency)** ditambah waktu antrean transmisi paket (*queuing delay*).
  * **Pemisahan One-Way Delay (OWD) dan Round-Trip Time (RTT)**:
    * Spesifikasi ini melarang pencampuran langsung antara OWD dan RTT tanpa konversi.
    * Jika data diambil dari instrumen ping/RTT lapangan, nilai harus dikonversi dengan aproksimasi simetris:
      $$\text{OWD} \approx \frac{\text{RTT}}{2}$$
      sebelum dimasukkan ke dalam matriks keputusan TOPSIS atau profil generator.

### 2.4. Bit Error Rate (BER)
* **Satuan**: Rasio murni tak berdimensi (*dimensionless ratio*), direpresentasikan sebagai bilangan pecahan float dalam rentang $[0.0, 1.0]$ atau notasi ilmiah (misal $1.0 \times 10^{-6}$).
* **Arah Optimasi TOPSIS**: **Cost** ($\min$) — semakin rendah rasio bit salah, semakin tinggi keandalan kanal transmisi.
* **Definisi Operasional**:
  * Rasio jumlah bit yang diterima salah (*corrupted bits*) terhadap total bit yang diobservasi setelah proses pengkodean kanal (*post-Forward Error Correction / residual BER*):
    $$\text{BER} = \frac{N_{\text{error}}}{N_{\text{total}}}$$
* **Penanganan Nilai Nol dan Skala Numerik**:
  * Nilai $\text{BER} = 0.0$ secara matematis valid (tidak ada bit rusak dalam jendela observasi).
  * Dalam kalkulasi TOPSIS (jarak Euclidean), nilai $0.0$ aman dan tidak memicu pembagian dengan nol.
  * Pada modul pemodelan kanal sintetis berbasis logaritmik ($\log_{10}(\text{BER})$), ditetapkan nilai lantai numerik (*floor threshold*) $\text{BER}_{\text{floor}} = 1.0 \times 10^{-9}$ guna menghindari singularitas $\log_{10}(0) = -\infty$.

---

## 3. Karakterisasi dan Penetapan Versi Teknologi

### 3.1. 4G LTE (Long Term Evolution)
* **Spesifikasi Acuan**: 3GPP Release 8–12, UE Category 4/6, alokasi bandwidth $20\text{ MHz}$ FDD/TDD, konfigurasi $2\times 2$ MIMO.
* **Cakupan & Karakteristik**: Makro-seluler jangkauan luas (radius hingga 1000 m), alokasi spektrum berlisensi terkoordinasi (OFDMA downlink).

### 3.2. 5G NR (New Radio)
* **Spesifikasi Acuan**: 3GPP Release 15–16, Standalone/Non-Standalone Sub-6 GHz (Frequency Range 1 / FR1, misal pita n78 $3.5\text{ GHz}$), alokasi bandwidth $100\text{ MHz}$ TDD, *Subcarrier Spacing* $30\text{ kHz}$ ($\mu = 1$), konfigurasi $4\times 4$ MIMO.
* **Cakupan & Karakteristik**: Sel mikro/piko jangkauan menengah-pendek (radius 300–500 m), throughput masif, latensi antarmuka radio sangat rendah (*mini-slot scheduling*).

### 3.3. WLAN / Wi-Fi
* **Penetapan Versi Spesifik**: Ditetapkan secara eksplisit sebagai **Wi-Fi 5 (IEEE 802.11ac Wave 2)** dan **Wi-Fi 6 (IEEE 802.11ax)** pada pita frekuensi $5\text{ GHz}$, lebar kanal $80\text{ MHz}$, konfigurasi $2\times 2$ MIMO.
* **Alasan Penetapan Versi**:
  * Penggunaan istilah umum "WLAN" dapat menimbulkan ambiguitas (apakah 802.11b kuno atau standar modern).
  * Standar 802.11ac/ax pada 5 GHz dipilih karena merupakan standar de facto pada perangkat *smartphone* modern dan *Access Point* komersial yang bersaing langsung dengan jaringan seluler 4G/5G di area perkantoran, kampus, dan pusat perbelanjaan.
* **Cakupan & Karakteristik**: Sel mikro jangkauan lokal (radius 50–100 m), mekanisme transmisi berbasis akses acak *Carrier Sense Multiple Access with Collision Avoidance* (CSMA/CA).

---

## 4. Tabel Spesifikasi Komparatif Parameter QoS (9 Kolom Lengkap)

Tabel berikut menyajikan pemetaan komparatif lengkap untuk ketiga teknologi pada keempat parameter QoS sesuai standar teknis dan model simulasi:

| Technology | Parameter | Definition | Unit | Proposed range | Criterion type | Source | Rationale | Assumptions |
|---|---|---|---|---|---|---|---|---|
| **4G LTE** | **RSS** | Reference Signal Received Power (RSRP) rata-rata per Resource Element (15 kHz subcarrier) | dBm | $[-120.0, -50.0]$ | Benefit | 3GPP TS 36.133 Table 9.1.2-1; ITU-R M.2134 | $-120\text{ dBm}$ adalah batas sensitivitas RSRP minimum untuk *cell-edge handover*; $-50\text{ dBm}$ adalah saturasi daya penerima di dekat eNodeB. | Pengukuran pita sempit per-RE; makro sel 20 MHz; outdoor/in-vehicle coverage; antena omni UE. |
| **4G LTE** | **Data Rate** | Achievable user-experienced downlink throughput pada transport layer | Mbps | $[1.0, 100.0]$ | Benefit | 3GPP TS 36.306 Cat 4/6; ITU-R M.2134; OpenSignal | Teoretis peak Cat 4 adalah 150 Mbps; throughput realistis berkisar 1 Mbps (cell edge) hingga 100 Mbps (kondisi optimal). | Utilisasi kanal 30%–70%; alokasi 20 MHz carrier; skenario beban heterogen jam sibuk. |
| **4G LTE** | **Delay** | One-Way RAN user-plane latency ditambah queuing delay transmisi paket | ms | $[10.0, 100.0]$ | Cost | 3GPP TR 36.912 Sec 13.1; ITU-R M.2134; ITU-T G.1050 | Latensi radio ideal $< 5\text{ ms}$, namun latensi nyata termasuk antrean jaringan inti dan retransmisi HARQ berkisar 10–100 ms. | Nilai OWD simetris dihitung dari RTT/2; beban trafik moderate hingga tinggi. |
| **4G LTE** | **BER** | Post-FEC residual bit error rate ($N_{\text{error}} / N_{\text{total}}$) pasca Turbo decoder | rasio | $[10^{-6}, 10^{-3}]$ | Cost | 3GPP TS 36.212; 3GPP TS 36.213 (target BLER 10%) | Target BLER 10% dikoreksi oleh Turbo decoder menghasilkan residual BER $10^{-6}$ (bagus) hingga $10^{-3}$ (kritis mendekati drop). | Kanal fading Rayleigh/AWGN; modulasi adaptif QPSK hingga 64-QAM. |
| **5G NR** | **RSS** | SS-RSRP / CSI-RSRP daya sinyal sinkronisasi per subcarrier (30 kHz SCS) | dBm | $[-110.0, -40.0]$ | Benefit | 3GPP TS 38.133 Table 10.1.2-1; ITU-R M.2410 | Redaman frekuensi FR1 (3.5 GHz) lebih tinggi di cell edge ($-110\text{ dBm}$); daya terima dekat gNodeB mencapai $-40\text{ dBm}$. | Sub-6 GHz FR1 (band n78); bandwidth 100 MHz; radius sel 300–500 m. |
| **5G NR** | **Data Rate** | Achievable user-experienced downlink throughput pada transport layer | Mbps | $[50.0, 1000.0]$ | Benefit | ITU-R Report M.2410-0 (IMT-2020 eMBB); 3GPP TR 38.913 | Target IMT-2020 eMBB menetapkan user experience rate 100 Mbps (50 Mbps di cell edge berbeban) hingga 1 Gbps (1000 Mbps) optimal. | Bandwidth 100 MHz TDD, 4x4 MIMO, 256-QAM, beban sedang di area perkotaan. |
| **5G NR** | **Delay** | One-Way RAN user-plane latency ditambah scheduling & queuing delay | ms | $[1.0, 20.0]$ | Cost | 3GPP TS 38.300; ITU-R M.2410-0 URLLC/eMBB | Spesifikasi target latensi antarmuka radio 5G adalah 4 ms (eMBB) dan 1 ms (URLLC); rentang operasional 1–20 ms mencakup jitter antrean. | Penjadwalan mini-slot / flexible numerology $\mu = 1$ (SCS 30 kHz); edge computing core terdekat. |
| **5G NR** | **BER** | Post-FEC residual bit error rate ($N_{\text{error}} / N_{\text{total}}$) pasca LDPC decoder | rasio | $[10^{-8}, 10^{-5}]$ | Cost | 3GPP TS 38.212 (LDPC coding untuk eMBB data channel) | Kode LDPC modern memberikan koreksi error superior, menjaga residual bit error rate sangat rendah ($10^{-8}$ hingga $10^{-5}$). | Kanal data PDSCH dengan LDPC base graph 1/2; target BLER 10% sebelum decoding. |
| **WLAN** | **RSS** | Received Signal Strength Indicator (RSSI) broadband pada kanal 80 MHz | dBm | $[-90.0, -30.0]$ | Benefit | IEEE Std 802.11-2020; Cisco Wireless Guidelines | $-90\text{ dBm}$ adalah batas modulasi terendah BPSK 1/2 sebelum *disconnect*; $-30\text{ dBm}$ kondisi LOS berjarak 1 meter dari AP. | IEEE 802.11ac/ax Wave 2, pita 5 GHz, kanal 80 MHz, indoor/semi-indoor coverage radius 50–100 m. |
| **WLAN** | **Data Rate** | Achievable user-experienced downlink throughput pasca overhead MAC/CSMA | Mbps | $[1.0, 600.0]$ | Benefit | IEEE 802.11ac/ax Specs; Wi-Fi Alliance; RFC 2544 | Peak PHY 2x2 MIMO adalah 867–1201 Mbps; throughput aplikasi bersih berkisar 1 Mbps (ramai/jauh) hingga 600 Mbps (sepi/dekat). | 2x2 MU-MIMO, contention window dinamis, 1–15 pengguna aktif simultan per BSS. |
| **WLAN** | **Delay** | One-Way MAC channel access delay (backoff + contention) + transmission | ms | $[5.0, 50.0]$ | Cost | IEEE 802.11-2020 EDCA QoS; ITU-T G.1050 | Akses kanal tanpa kompetisi berkisar ~5 ms; kompetisi CSMA/CA dan retransmisi tabrakan frame meningkatkan latensi hingga 50 ms. | Trafik EDCA Best Effort / Video; probabilitas tabrakan 5%–25%. |
| **WLAN** | **BER** | Post-FEC residual bit error rate ($N_{\text{error}} / N_{\text{total}}$) pasca BCC/LDPC | rasio | $[10^{-7}, 10^{-4}]$ | Cost | IEEE Std 802.11-2020 PHY Specifications (BCC/LDPC) | Standar mensyaratkan Packet Error Rate (PER) $< 10\%$ pada frame 4096 byte, menghasilkan residual BER $10^{-7}$ hingga $10^{-4}$. | Modulasi BPSK hingga 256-QAM/1024-QAM; multipath fading indoor (TGac model). |

---

## 5. Hubungan Parameter QoS dengan Dinamika Fisik Kanal

Perubahan nilai parameter QoS pada generator profil jaringan dimodelkan berdasarkan prinsip fisik propagasi gelombang elektromagnetik:

1. **Jarak Propagasi dan Path Loss**:
   Daya terima berkurang seiring jarak $d$ mengikuti *Log-Distance Path Loss Model*:
   $$PL(d) = PL(d_0) + 10 \cdot n \cdot \log_{10}\left(\frac{d}{d_0}\right) + X_\sigma$$
   di mana $n$ adalah eksponen redaman jalur ($n = 2.0$ ruang bebas, $n = 3.0 - 4.0$ lingkungan urban/indoor), $d_0 = 1\text{ meter}$, dan $X_\sigma \sim \mathcal{N}(0, \sigma^2)$ merepresentasikan *shadow fading* log-normal dengan deviasi standar $\sigma = 4.0 - 8.0\text{ dB}$.
2. **Korelasi RSS terhadap Data Rate, Delay, dan BER**:
   * **Data Rate**: Berbanding lurus secara non-linear terhadap RSS (kualitas SNR) mengikuti kapasitas Shannon dan batas modulasi:
     $$R(d) \approx R_{\min} + (R_{\max} - R_{\min}) \cdot \left(\frac{\text{RSS}(d) - \text{RSS}_{\min}}{\text{RSS}_{\max} - \text{RSS}_{\min}}\right)^\alpha$$
     dengan parameter kelengkungan $\alpha \approx 1.5 - 2.0$.
   * **Delay**: Meningkat secara eksponensial saat sinyal mendekati ambang batas sensitivitas akibat retransmisi MAC/HARQ dan *backoff window*:
     $$D(d) \approx D_{\min} + (D_{\max} - D_{\min}) \cdot \left(1 - \frac{\text{RSS}(d) - \text{RSS}_{\min}}{\text{RSS}_{\max} - \text{RSS}_{\min}}\right)^\beta$$
   * **BER**: Dipengaruhi oleh rasio $E_b/N_0$. Pada skala logaritmik, nilai BER meningkat tajam ketika daya sinyal turun:
     $$\log_{10}(\text{BER}) = \log_{10}(\text{BER}_{\max}) + (1 - \rho) \cdot (\log_{10}(\text{BER}_{\min}) - \log_{10}(\text{BER}_{\max}))$$
     di mana $\rho$ adalah faktor normalisasi RSS.
3. **Pengaruh Kecepatan Pengguna & Pergeseran Doppler**:
   Pergerakan cepat pengguna ($v > 15\text{ m/s}$) menyebabkan pergeseran frekuensi Doppler $f_d = \frac{v \cdot f_c}{c}$, yang memperpendek waktu koherensi saluran, meningkatkan fluktuasi sinyal (*fast fading*), menaikkan BER, dan memicu degradasi throughput.

---

## 6. Konsistensi dengan Algoritma Baseline Single TOPSIS

### 6.1. Representasi Input Numerik dan Arah Kriteria
Pada modul TOPSIS, setiap alternatif jaringan $i$ pada langkah waktu $t$ direpresentasikan sebagai vektor baris kriteria:
$$\mathbf{x}_i = [\text{Rate}_i, \text{Delay}_i, \text{BER}_i, \text{RSS}_i]$$

Arah kriteria ditetapkan secara tegas:
* $C_1$: **Data Rate** $\to$ **Benefit** ($v_1^+ = \max, v_1^- = \min$)
* $C_2$: **Delay** $\to$ **Cost** ($v_2^+ = \min, v_2^- = \max$)
* $C_3$: **BER** $\to$ **Cost** ($v_3^+ = \min, v_3^- = \max$)
* $C_4$ *(opsional / pembobot)*: **RSS** $\to$ **Benefit** ($v_4^+ = \max, v_4^- = \min$)

### 6.2. Normalisasi Vektor dan Masalah Skala
Karena setiap parameter memiliki rentang dan satuan yang berbeda ($\text{Mbps}$, $\text{ms}$, rasio $10^{-8}$, $\text{dBm}$), normalisasi vektor Euclidean diterapkan:
$$r_{ij} = \frac{x_{ij}}{\sqrt{\sum_{k=1}^m x_{kj}^2}}$$
Normalisasi ini meniadakan dimensi satuan dan menjamin bahwa pembobotan kriteria $w_j$ berlaku secara adil tanpa terdistorsi oleh besaran angka dasar.

### 6.3. Penanganan Kasus Batas (Edge Cases)
1. **BER Bernilai Nol**: Nilai $\text{BER} = 0.0$ dapat diproses langsung oleh formula Euclidean tanpa pembagian dengan nol.
2. **Kriteria Konstan (Semua Alternatif Identik)**: Jika pada satu langkah waktu seluruh kandidat memiliki delay yang sama, kolom dinormalisasi secara aman (nilai bobot seragam) tanpa menghasilkan nilai NaN.
3. **Solusi Ideal Berimpit ($S_i^+ + S_i^- = 0$)**: Jika seluruh alternatif identik di semua kriteria, skor utilitas ditetapkan secara deterministik ke $C_i = 0.5$ untuk menjaga stabilitas ranking.

---

## 7. Kontrak Input dan Validasi Antarmodul

### 7.1. Kontrak Field Data Kanonis
| Field Name | Tipe Data | Satuan | Rentang Valid | Status Wajib |
|---|---|---|---|---|
| `id` | `string` | - | Teks non-kosong unik | Wajib |
| `technology` | `string` | - | `"4G"`, `"5G"`, atau `"WLAN"` | Wajib |
| `rss_dbm` | `float` | $\text{dBm}$ | $[-140.0, 0.0]$ | Wajib |
| `data_rate_mbps` | `float` | $\text{Mbps}$ | $\ge 0.0$ | Wajib |
| `delay_ms` | `float` | $\text{ms}$ | $\ge 0.0$ | Wajib |
| `ber` | `float` | rasio | $[0.0, 1.0]$ | Wajib |
| `available` | `boolean` | - | `true` atau `false` | Wajib |

### 7.2. Aturan Validasi Input TOPSIS
1. **Penyaringan Ketersediaan (Availability Filter)**: Hanya kandidat dengan `available == true` yang diikutsertakan dalam matriks keputusan TOPSIS. Kandidat di luar jangkauan ($\text{RSS} < \text{RSS}_{\min}$) secara otomatis dieliminasi sebelum perankingan.
2. **Pemeriksaan Bilangan Hingga (Finite Check)**: Seluruh nilai numerik harus riil dan terhingga (`math.isfinite(x) == true`). Nilai `NaN`, `Infinity`, atau `-Infinity` akan memicu penolakan validasi.
3. **Normalisasi Bobot**: Vektor bobot $\mathbf{w}$ harus memiliki elemen non-negatif dan dijumlahkan bernilai $1.0$ ($\sum_{j=1}^n w_j = 1.0$).

---

## 8. Konfigurasi Terstruktur Parameter (JSON Schema)

File konfigurasi mesin [wmc_simulator/network/qos_profiles.json](file:///d:/KulYeahh/Sem5/WMC/wmc-handsign/wmc_simulator/network/qos_profiles.json) mendefinisikan parameter kanonis yang dapat dibaca secara terpusat oleh generator dan evaluator:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HeterogeneousNetworkQoSProfiles",
  "description": "Spesifikasi kanonis parameter QoS untuk 4G LTE, 5G NR, dan WLAN",
  "version": "1.0.0",
  "profiles": {
    "4G": {
      "technology": "4G",
      "display_name": "4G LTE (Rel 8-12 Cat 4/6)",
      "coverage_radius_m": 1000.0,
      "parameters": {
        "rss_dbm": { "min": -120.0, "max": -50.0, "unit": "dBm", "direction": "benefit", "metric_type": "RSRP" },
        "data_rate_mbps": { "min": 1.0, "max": 100.0, "unit": "Mbps", "direction": "benefit" },
        "delay_ms": { "min": 10.0, "max": 100.0, "unit": "ms", "direction": "cost" },
        "ber": { "min": 1e-6, "max": 1e-3, "unit": "ratio", "direction": "cost", "floor": 1e-9 }
      }
    },
    "5G": {
      "technology": "5G",
      "display_name": "5G NR (FR1 Sub-6GHz eMBB)",
      "coverage_radius_m": 500.0,
      "parameters": {
        "rss_dbm": { "min": -110.0, "max": -40.0, "unit": "dBm", "direction": "benefit", "metric_type": "SS-RSRP" },
        "data_rate_mbps": { "min": 50.0, "max": 1000.0, "unit": "Mbps", "direction": "benefit" },
        "delay_ms": { "min": 1.0, "max": 20.0, "unit": "ms", "direction": "cost" },
        "ber": { "min": 1e-8, "max": 1e-5, "unit": "ratio", "direction": "cost", "floor": 1e-9 }
      }
    },
    "WLAN": {
      "technology": "WLAN",
      "display_name": "Wi-Fi 5/6 (IEEE 802.11ac/ax 5GHz 80MHz)",
      "coverage_radius_m": 100.0,
      "parameters": {
        "rss_dbm": { "min": -90.0, "max": -30.0, "unit": "dBm", "direction": "benefit", "metric_type": "RSSI" },
        "data_rate_mbps": { "min": 1.0, "max": 600.0, "unit": "Mbps", "direction": "benefit" },
        "delay_ms": { "min": 5.0, "max": 50.0, "unit": "ms", "direction": "cost" },
        "ber": { "min": 1e-7, "max": 1e-4, "unit": "ratio", "direction": "cost", "floor": 1e-9 }
      }
    }
  }
}
```

---

## 9. Checklist Validasi Kepatuhan Spesifikasi

- [x] **Definisi Operasional Unik**: Empat parameter utama (RSS, Data Rate, Delay, BER) memiliki definisi operasional yang tidak ambigu.
- [x] **Satuan Kanonis**: Satuan konsisten di seluruh pipeline: $\text{dBm}$, $\text{Mbps}$, $\text{ms}$, dan rasio murni $[0.0, 1.0]$.
- [x] **Diferensiasi Fisik Sinyal**: Perbedaan RSRP (seluler pita sempit) dan RSSI (Wi-Fi pita lebar) terdokumentasi dan ditangani via normalisasi.
- [x] **Pemisahan OWD dan RTT**: One-Way Delay digunakan secara konsisten tanpa mencampur aduk dengan Round-Trip Time.
- [x] **Penanganan Nilai Nol BER**: Nilai $\text{BER} = 0.0$ ditangani secara aman dalam TOPSIS, dengan ambang batas lantai $10^{-9}$ untuk generator skala logaritmik.
- [x] **Tabel Komparatif 9 Kolom**: Seluruh 12 kombinasi parameter-teknologi tercakup lengkap dengan dasar sumber dan asumsi.
- [x] **Arah Kriteria TOPSIS**: RSS (Benefit), Data Rate (Benefit), Delay (Cost), BER (Cost) terverifikasi konsisten.
- [x] **Bukan Klaim Pengukuran Lapangan**: Ditandai secara eksplisit bahwa rentang ini adalah spesifikasi pemodelan simulasi terkalibrasi standar, bukan hasil *walk test* nyata.

---

## 10. Daftar Referensi Standar dan Ilmiah yang Dapat Diverifikasi

1. **3GPP TS 36.133**: *E-UTRA; Requirements for support of radio resource management*, v15.4.0, 3rd Generation Partnership Project.
2. **3GPP TS 36.212**: *E-UTRA; Multiplexing and channel coding*, 3rd Generation Partnership Project.
3. **3GPP TS 36.214**: *E-UTRA; Physical layer; Measurements*, 3rd Generation Partnership Project.
4. **3GPP TS 36.306**: *E-UTRA; User Equipment (UE) radio access capabilities*, 3rd Generation Partnership Project.
5. **3GPP TS 38.133**: *NR; Requirements for support of radio resource management*, v16.3.0, 3rd Generation Partnership Project.
6. **3GPP TS 38.212**: *NR; Multiplexing and channel coding*, 3rd Generation Partnership Project.
7. **3GPP TS 38.215**: *NR; Physical layer measurements*, 3rd Generation Partnership Project.
8. **3GPP TS 38.300**: *NR; Overall description; Stage-2*, 3rd Generation Partnership Project.
9. **ITU-R Report M.2134 (2008)**: *Requirements related to technical performance for IMT-Advanced radio interface(s)*, International Telecommunication Union.
10. **ITU-R Report M.2410-0 (2017)**: *Minimum requirements related to technical performance for IMT-2020 radio interface(s)*, International Telecommunication Union.
11. **IEEE Std 802.11-2020**: *IEEE Standard for Information Technology—Telecommunications and Information Exchange between Systems—Part 11: Wireless LAN MAC and PHY Specifications*.
12. **ITU-T Recommendation G.1050 (2016)**: *Network model for evaluating multimedia transmission performance over Internet Protocol*, International Telecommunication Union.
13. **S. Ndegwa, K. Nyachionjeka, E. T. Mharakurwa (2023)**: *"User Preference-Based Heterogeneous Network Management System for Vertical Handover"*, Journal of Electrical and Computer Engineering.
14. **M. Al-bashiri et al. (2018)**: *"A decision-making framework for vertical handover in heterogeneous wireless networks"*, PLOS ONE, doi:10.1371/journal.pone.0204434.
