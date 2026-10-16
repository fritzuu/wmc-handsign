# Dokumen Asumsi Simulasi dan Keterbatasan Model QoS Jaringan Heterogen

Dokumen ini mendokumentasikan asumsi simulasi, model propagasi, faktor dinamis kanal nirkabel, keterbatasan model komputasi, serta keputusan yang masih memerlukan penegasan dari peneliti untuk evaluasi handover jaringan heterogen (4G LTE, 5G NR, dan WLAN) menggunakan *Single TOPSIS Utility Function*.

---

## 1. Skenario Lingkungan dan Profil Pengguna

### 1.1. Topologi dan Lingkungan Geografis
* **Tipe Lingkungan**: Area perkotaan padat (*Dense Urban / Campus Environment*) yang mencakup zona luar ruangan (*outdoor*) dan zona dalam ruangan (*indoor*).
* **Penempatan Node Jaringan**:
  * **4G LTE eNodeB**: Makro-seluler terpasang di menara dengan tinggi efektif 25–30 meter, menyediakan payung cakupan luas (*umbrella coverage*) dengan radius jangkauan efektif $1000\text{ meter}$.
  * **5G NR gNodeB**: Sel mikro/piko Sub-6 GHz (pita n78, frekuensi tengah $3.5\text{ GHz}$) terpasang pada tiang/dinding gedung dengan tinggi efektif 10–15 meter, radius cakupan efektif $300 - 500\text{ meter}$.
  * **WLAN Access Point (AP)**: Wi-Fi 5 / 6 ($5\text{ GHz}$, kanal $80\text{ MHz}$) terpasang di langit-langit ruangan (*ceiling-mounted*) dengan tinggi efektif 3 meter, radius cakupan efektif $50 - 100\text{ meter}$.

### 1.2. Dinamika Mobilitas Pengguna (Random Waypoint Model)
* Pengguna (*User Equipment / UE*) bergerak di dalam area simulasi mengikuti model mobilitas stokastik *Random Waypoint* (RWP).
* **Kelas Kecepatan Pengguna**:
  1. *Pedestrian (Pejalan Kaki)*: $v \in [0.5, 1.5]\text{ m/s}$ (kecepatan tipikal di dalam gedung/trotoar).
  2. *Urban Vehicular (Kendaraan Kota / Sepeda)*: $v \in [5.0, 15.0]\text{ m/s}$ (kecepatan rata-rata di jalan arteri kota).
  3. *High-Speed Transit (Kendaraan Cepat)*: $v > 15.0\text{ m/s}$ (diasumsikan memicu redaman Doppler tinggi dan waktu tinggal sel yang sangat singkat).

---

## 2. Pemodelan Matematis Propagasi dan Parameter Kanal

Generator profil jaringan mensintesis parameter QoS berdasarkan model fisika propagasi nirkabel terkalibrasi:

### 2.1. Model Redaman Daya Terima (Path Loss Model)
Daya sinyal yang diterima ($\text{RSS}$) pada jarak $d$ (meter) dari pemancar dimodelkan menggunakan *Log-Distance Path Loss Model* dengan bayangan log-normal (*Log-Normal Shadowing*):

$$\text{RSS}(d) = P_{\text{tx}} - PL(d)$$

$$PL(d) = PL(d_0) + 10 \cdot n \cdot \log_{10}\left(\frac{d}{d_0}\right) + X_\sigma$$

Keterangan parameter:
* $d_0 = 1.0\text{ meter}$ (jarak referensi medan jauh).
* $n$: Eksponen redaman jalur (*path loss exponent*):
  * Lingkungan ruang bebas (*free space*): $n = 2.0$
  * Lingkungan makro-urban 4G: $n = 3.5$
  * Lingkungan urban mikro 5G FR1: $n = 3.8$
  * Lingkungan indoor/dinding WLAN 5 GHz: $n = 4.0$
* $X_\sigma \sim \mathcal{N}(0, \sigma^2)$: Variasi bayangan skala besar (*shadow fading*), di mana standar deviasi $\sigma$ bernilai $4.0\text{ dB}$ (WLAN) hingga $8.0\text{ dB}$ (seluler makro).

### 2.2. Model Redaman Penetrasi Dinding (Penetration Loss)
* Frekuensi tinggi ($5\text{ GHz}$ pada Wi-Fi dan $3.5\text{ GHz}$ pada 5G NR) mengalami pelemahan tembus dinding gedung (*building penetration loss*) sebesar $10 - 20\text{ dB}$ per partisi beton.
* Sebaliknya, sinyal 4G pada frekuensi $800 - 1800\text{ MHz}$ memiliki penetrasi struktural yang lebih baik, sehingga di dalam ruangan tertutup yang jauh dari AP Wi-Fi, sinyal 4G sering kali tetap stabil saat sinyal Wi-Fi atau 5G telah terdegradasi.

### 2.3. Model Korelasi QoS terhadap Kualitas Sinyal
1. **Data Rate ($R$)**:
   Dimodelkan secara non-linear terhadap daya sinyal yang dinormalisasi $\rho = \frac{\text{RSS} - \text{RSS}_{\min}}{\text{RSS}_{\max} - \text{RSS}_{\min}} \in [0, 1]$:
   $$R = R_{\min} + (R_{\max} - R_{\min}) \cdot \rho^\alpha$$
   Eksponen $\alpha = 1.5$ merepresentasikan sifat adaptasi modulasi (*link adaptation*) di mana modulasi orde tinggi (misal 256-QAM) hanya dapat dicapai pada kondisi SNR sangat baik.
2. **Delay ($D$)**:
   Dimodelkan meningkat drastis di dekat batas jangkauan sel akibat kegagalan transmisi bingkai dan mekanisme *retransmission backoff*:
   $$D = D_{\min} + (D_{\max} - D_{\min}) \cdot (1 - \rho)^\beta$$
   dengan $\beta = 1.2$.
3. **Bit Error Rate ($\text{BER}$)**:
   Pada domain logaritmik:
   $$\log_{10}(\text{BER}) = \log_{10}(\text{BER}_{\max}) + (1 - \rho) \cdot \left(\log_{10}(\text{BER}_{\min}) - \log_{10}(\text{BER}_{\max})\right)$$
   Hubungan ini mencerminkan karakteristik kurva air terjun (*waterfall curve*) fungsi error $Q(\sqrt{\text{SNR}})$ pada sistem modulasi digital.

---

## 3. Keterbatasan Model Simulasi

1. **Bukan Data Lapangan Riil (Synthetic vs Empirical)**:
   * Data yang dihasilkan adalah hasil formulasi stokastik dan model matematis terkalibrasi standar, bukan hasil penangkapan paket riil dari modem *chipset* fisik (*baseband trace*).
   * Generator ini berfungsi untuk validasi deterministik, komparasi algoritma, dan uji ketahanan (*stress testing*) algoritma TOPSIS dalam kondisi terkontrol yang dapat diulang (*reproducible*).
2. **5G Tidak Selalu Lebih Baik (Non-Monotonik)**:
   * Skenario simulasi menolak penyederhanaan yang menganggap 5G selalu lebih unggul dari 4G atau Wi-Fi dalam segala kondisi.
   * Pada jarak $> 300\text{ meter}$ dari gNodeB, daya terima 5G turun drastis di bawah ambang batas sensitivitas, sehingga 4G LTE atau WLAN lokal akan dipilih sebagai alternatif yang lebih baik oleh TOPSIS.
3. **Keterbatasan CSMA/CA pada Pemodelan WLAN**:
   * Model generator saat ini mengabstraksikan kepadatan pengguna WLAN ke dalam variasi redaman acak dan batas data rate, tanpa mensimulasikan antrean paket diskrit level slot waktu MAC 802.11 secara penuh.

---

## 4. Keputusan yang Belum Tervalidasi (Membutuhkan Penegasan Peneliti)

Berikut adalah beberapa asumsi eksperimen yang masih terbuka dan membutuhkan keputusan final dari peneliti utama:

1. **Model Interferensi Latar Belakang (Co-Channel Interference)**:
   * *Saat ini*: Generator mengasumsikan interferensi dimodelkan melalui variasi gaussian (*shadow fading* dan deviasi acak).
   * *Opsi Peneliti*: Menentukan apakah perlu mensimulasikan model *Signal-to-Interference-plus-Noise Ratio* (SINR) eksplisit dengan menempatkan interferer aktif di sekitar node.
2. **Bobot Kriteria Dinamis per Skenario Pengguna**:
   * *Saat ini*: Modul menyediakan profil bobot berdasarkan 4 kelas trafik standar (Conversational, Streaming, Interactive, Background).
   * *Opsi Peneliti*: Menentukan apakah bobot preferensi pengguna bersifat statis selama satu sesi perjalanan mobilitas atau dapat berganti secara dinamis berdasarkan jenis aplikasi yang aktif.
3. **Ambang Batas Handover Histeresis**:
   * *Saat ini*: Evaluasi baseline TOPSIS memeringkat jaringan pada setiap langkah waktu ($t$).
   * *Opsi Peneliti*: Menentukan batas toleransi histeresis ($\Delta C$ dan *Time-to-Trigger / TTT*) untuk meredam efek *ping-pong handover* saat skor utilitas antara dua alternatif jaringan sangat berdekatan.
