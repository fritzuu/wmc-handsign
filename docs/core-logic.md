# Formulasi core logic Dart

Kode berada di `lib/core/handover/`. Angka berikut mencatat parameter paper dan adaptasi proyek agar eksperimen dapat diperiksa dan diulang.

## Input FIS QoS

Input: Mbps, ms, BER rasio, dBm, m/s. Angka harus finite. Snapshot immutable; daftar input disalin. ID duplikat ditolak, jaringan unavailable tidak ikut ranking.

Tabel 1 Ndegwa halaman 6 setelah konversi satuan:

| Kelas | Data rate Mbps low–high | Skala delay ms | Skala BER rasio |
| --- | --- | --- | --- |
| Conversational | 0.064–1.920 | 100 | 0.0001 |
| Streaming | 0.005–0.700 | 400 | 0.0001 |
| Interactive | 0.0282–0.500 | 200 | 0.00001 |
| Background | 0.001–0.024 | 600 | 0.00001 |

Rate dinormalisasi `(rate-low)/(high-low)`. Delay dan BER dinormalisasi `value/scale`. Semua di-clamp ke 0–1. Streaming memakai 0–400 ms sebagai domain cost, bukan menganggap delay di bawah 300 ms buruk. Paper menulis 300–400 ms tetapi tidak memberi breakpoint lengkap; pemakaian batas atas sebagai skala adalah adaptasi. BER tunggal 0.01% dipakai sebagai skala, bukan input konstan. Rentang ini bukan SLA universal aplikasi modern.

## RSS dan kecepatan

RSS dinormalisasi per teknologi sesuai dataflow terbaru. Rentang awal mengikuti generator Python: LTE −120 sampai −50, NR −110 sampai −40, WLAN −90 sampai −30 dBm. Ini adaptasi dari domain RSS tunggal −110 sampai −48 dBm pada paper. `HandoverConfiguration.rssRanges` dapat diganti. Tim sensor harus menyepakati metrik seluler (misalnya RSRP) dan mengkalibrasi rentang. Data generator dan baseline memakai normalisasi yang sama.

Speed dinormalisasi `mps*3.6/100`, lalu di-clamp. Nilai di atas 100 km/jam masuk fuzzy set tertinggi; ini tidak memperluas domain validitas paper.

## Mamdani

Gaussian: `exp(-0.5*((x-center)/sigma)^2)`.

Untuk n label: center = `i/(n-1)`, sigma = `0.45/(n-1)`. Semua domain numerik berada di 0–1. Kurva output terpotong di batas domain sehingga centroid ekstrem tidak tepat 0/1. Pusat dan sigma adalah adaptasi, bukan angka yang tercantum di paper.

Operator AND=min, implication=min, aggregation=max. Centroid mentah dihitung dengan integrasi trapezoid 400 segmen. Tidak ada random noise pada inference. [MathWorks gaussmf](https://www.mathworks.com/help/fuzzy/gaussmf.html) memberikan formula Gaussian.

### Kalibrasi arah respons

Audit menemukan bahwa centroid mentah tidak selalu monoton meskipun consequent aturan berurutan. Contoh: QoS 0.22 ke 0.23, RSS ternormalisasi 0.05, speed 60 km/jam menghasilkan HF mentah 0.699006 ke 0.700063. Kondisi membaik tetapi gate handover menjadi aktif.

Output produksi sekarang melewati `MonotoneMamdaniSurface`: sampling centroid pada grid reguler (12 segmen per sumbu untuk default), pembentukan envelope monoton, lalu interpolasi multilinear. QoS memakai lower envelope sehingga nilai kualitas pada node tidak dinaikkan; HF memakai upper envelope sehingga kebutuhan handover pada node tidak diturunkan. Koreksi ini dapat menggeser gate terhadap output mentah, sehingga hasil komparasi lama harus dihitung ulang. Nilai di antara node merupakan interpolasi, bukan evaluasi centroid mentah pada input tersebut.

Arah QoS: naik ketika rate naik, turun ketika delay/BER naik. Arah HF: turun ketika QoS/RSS naik, naik ketika speed naik. Sweep min/max mempertahankan urutan tiap sumbu; interpolasi antarnode mempertahankan arah tersebut di seluruh domain kontinu. Ini kalibrasi tambahan proyek, bukan langkah yang disebut paper. Centroid mentah tetap dapat diperiksa melalui `MamdaniSystem.evaluate()`. Surface default dicache agar sampling tidak diulang setiap tick/instance dengan rule base sama.

Tes menyapu 21×21×21 titik per surface untuk empat kelas QoS dan HF, termasuk batas domain, ditambah empat kasus gate dari audit. Tes ini memeriksa arah respons, bukan bukti performa lapangan atau kesamaan dengan model penulis.

### FIS 1

Input rate/delay/BER memiliki label Low/Medium/High (indeks 0–2). Output Poor/Average/Good/Excellent (0–3). Rule base lengkap 27 kombinasi per kelas dibentuk dengan:

```text
quality = wRate*rate/2 + wDelay*(1-delay/2) + wBer*(1-ber/2)
consequent = round(quality*3)
```

Bobot AHP menentukan consequent aturan, bukan langsung menghitung crisp QoS dari sensor. Crisp QoS berasal dari permukaan Mamdani yang sudah dikalibrasi. Pelengkapan aturan dengan bobot ini adalah rekonstruksi proyek karena PDF tidak memuat seluruh aturan. Low rate/High delay/High BER menghasilkan label Poor; High rate/Low delay/Low BER menghasilkan label Excellent, sesuai contoh paper. Per kelas dapat diganti dengan `QosCalculator(systems: ...)`; custom system juga melewati kalibrasi.

### FIS 2

Input QoS (0–3), RSS (0–2), speed (0–3). Output Very Low/Low/Average/High/Very High (0–4). Lengkap 48 kombinasi:

```text
urgency = 0.6*(1-qos/3) + 0.3*(1-rss/2) + 0.1*speed/3
urgency < 0.125 -> Very Low
urgency < 0.375 -> Low
urgency < 0.625 -> Average
urgency <=0.975 -> High
urgency > 0.975 -> Very High
```

Koefisien dan batas consequent adalah adaptasi yang perlu uji sensitivitas. Poor/Weak/High -> High, Excellent/Strong/Low -> Very Low, sesuai contoh paper. FIS dapat diganti lewat `HandoverFuzzyEvaluator(system: ...)`.

HF hanya dihitung jika jaringan aktif ada dan tersedia. Default threshold 0.7 dari bagian 3.2 paper, sama untuk empat kelas. HF sama dengan threshold menghasilkan tetap. Threshold dapat diganti per kelas sesuai rancangan PRD.

## TOPSIS

Subset bobot Tabel 2 AHP halaman 8:

| Kelas | Data rate | Delay | BER |
| --- | --- | --- | --- |
| Conversational | .03996 | .27983 | .03996 |
| Streaming | .2601 | .0695 | .0299 |
| Interactive | .03946 | .1111 | .2091 |
| Background | .05438 | .01863 | .2869 |

Normalisasi bobot: bagi masing-masing dengan jumlah tiga bobot baris. RSS/mobility/security/cost tidak menjadi kriteria TOPSIS karena PRD memilih tiga parameter QoS. Ranking tidak harus identik dengan grafik tujuh kriteria pada paper.

```text
r[i][j] = x[i][j] / sqrt(sum_i x[i][j]^2)
v[i][j] = r[i][j]*weight[j]
ideal[j] = max(v[:,j]) untuk rate; min untuk delay/BER
worst[j] = min(v[:,j]) untuk rate; max untuk delay/BER
Dplus[i] = sqrt(sum_j (v[i][j]-ideal[j])^2)
Dminus[i] = sqrt(sum_j (v[i][j]-worst[j])^2)
score[i] = Dminus[i]/(Dplus[i]+Dminus[i])
```

Sebelum dikuadratkan, kolom diskalakan dengan maksimum untuk menghindari overflow. Kolom nol berkontribusi nol. Jika semua jarak nol, score=0.5. Seri memilih jaringan aktif, kemudian ID. Delay/BER tetap cost tanpa pembalikan ganda.

Formula TOPSIS standar melengkapi uraian konseptual paper bagian 3.3.2. Referensi langkah matematis: [Al-bashiri et al. 2018, TOPSIS technique](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0204434).

## Pembanding dan stabilisasi

`baselineTopsisRanking` memakai kriteria/bobot sama setiap tick, tanpa gate HF. `baselineRssNetworkId` memakai normalisasi RSS yang sama dengan FIS. TOPSIS langsung ini tidak mereproduksi utility function studi baseline yang dirujuk paper.

Stabilizer opsional mengikuti dataflow: gain minimum score TOPSIS=0.05, dwell=3 detik. Angka ini adaptasi. Target yang sama harus bertahan selama dwell; gain dibandingkan dengan jaringan aktif pada tick yang sama. Pending dihapus ketika hasil mentah tetap/insufficientData, gain kurang, kelas/jaringan aktif berubah, atau reset. Bila stream sensor terputus, caller mengirim insufficientData atau reset agar dwell tidak dianggap kontinu.

Stabilizer tidak mengganti jaringan aktif OS. Logger menyimpan raw dan final; evaluator mendefinisikan event perubahan rekomendasi sebelum menghitung metrik. Untuk mengisolasi efek Fuzzy, bandingkan raw Fuzzy-TOPSIS dengan raw TOPSIS. Jika stabilisasi digunakan pada komparasi utama, terapkan kebijakan sama pada pembanding dan catat desainnya.

Sensor, timestamp/freshness, EMA, generator hybrid Dart, UI, logger, probe validasi independen, metrik rekomendasi dan ekspor belum diintegrasikan. Tes sintetis tidak membuktikan keunggulan performa ataupun hasil walk test.
