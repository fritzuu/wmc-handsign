# Prompt Wireframe — WMC Vertical Handover Simulator
## Berdasarkan PRD v1.0 (Simulator Vertical Handover Berbasis Preferensi Aplikasi)

> **Paper acuan:** Ndegwa et al. (2023) — "User Preference-Based Heterogeneous Network Management System for Vertical Handover"
>
> Gunakan prompt di bawah ini di tools seperti **Figma AI, Uizard, Galileo AI, Midjourney, atau DALL-E** untuk generate wireframe tiap halaman.
>
> **Tips:**
> - Untuk **Midjourney**: tambahkan `--ar 9:16 --style raw` di akhir prompt
> - Untuk **DALL-E / ChatGPT**: paste langsung
> - Untuk **Figma AI / Uizard / Galileo AI**: copy-paste prompt langsung
> - Jika hasil kurang presisi, pecah prompt per section dan generate satu-satu

---

## Daftar Halaman (10 Screen)

| # | Halaman | Keterangan PRD |
|---|---------|----------------|
| 1 | Splash Screen | Branding app |
| 2 | Home Dashboard | Overview + quick actions |
| 3 | Konfigurasi Eksperimen | Section 6 — rancangan eksperimen |
| 4 | Konfigurasi Fuzzy & Ambang | FR-05, FR-06 — Fuzzy Logic + threshold per kelas |
| 5 | Profil Bobot TOPSIS | FR-07, FR-08 — bobot kriteria per kelas aplikasi |
| 6 | Monitor Simulasi | Section 3 — alur simulator real-time |
| 7 | Log Keputusan | FR-10 — detail log setiap keputusan handover |
| 8 | Hasil Metrik Evaluasi | Section 5 — 4 metrik evaluasi |
| 9 | Grafik Komparasi | FR-12 — Fuzzy-TOPSIS vs Baseline RSS-only |
| 10 | Ekspor Data | FR-11 — ekspor log dan ringkasan ke JSON/CSV |

---

## PROMPT 1 — Splash Screen

```
Design a mobile app splash screen wireframe in flat minimal style (9:16 portrait, 390x844px). No device frame.

Background: solid dark navy blue (#0D1B2A) filling the entire screen.

Center of screen (vertically and horizontally centered), arranged top to bottom:
- A white outlined icon (64x64px) showing three overlapping signal/network tower symbols representing 4G, 5G, and WiFi networks
- 20px gap below icon
- App name "WMC Simulator" in bold white sans-serif font, size 28px, letter-spacing 1px
- 8px gap below
- Subtitle "Vertical Handover Decision System" in light steel blue (#78909C) regular font, size 14px
- 6px gap below
- Second subtitle "Fuzzy-TOPSIS vs RSS Baseline" in light steel blue (#78909C) regular font, size 12px
- 24px gap below
- A thin horizontal divider line (60px wide, 1px, white 30% opacity), centered
- 16px gap below
- Text "Inspired by Ndegwa et al. (2023)" in white 40% opacity, italic, size 10px

Bottom of screen (32px from bottom edge, horizontally centered):
- A thin white circular loading spinner animation (20px diameter)
- 10px gap below
- Text "Memuat simulator..." in white 50% opacity, size 11px

Top-right corner (16px from top, 16px from right):
- Small text "v1.0" in white 30% opacity, size 10px
```

---

## PROMPT 2 — Home Dashboard

```
Design a mobile app home dashboard screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame.

TOP — App Bar (height 64px, white background, subtle bottom shadow 2px blur):
- Left side (16px from left): bold text "WMC Simulator" in dark navy (#0D1B2A), size 22px
- Below the title (2px gap): small text "Vertical Handover Simulator" in gray (#9E9E9E), size 11px
- Right side (16px from right): circular avatar placeholder (32px) with initials "RA" in white on blue (#1565C0) background

SECTION 1 — Status Card (16px margin left/right, 12px below app bar):
- Rounded card (border-radius 16px), background gradient-like two-tone: left half dark navy (#1A237E), right half steel blue (#1565C0)
- Height: 100px, full width minus margins
- Inside card, left-aligned with 20px padding:
  - Small label "Status Terakhir" in white 70% opacity, size 11px
  - 4px below: bold text "Belum Ada Simulasi" in white, size 18px
  - 4px below: text "Mulai konfigurasi eksperimen untuk menjalankan simulasi pertama" in white 80% opacity, size 12px
- Right side inside card: a large faded white play circle icon (60px), 20% opacity

SECTION 2 — Alur Simulator (20px below status card):
- Section title: "Alur Simulator" bold, size 15px, dark (#212121), 16px from left, with small blue dot (8px) before the text
- 12px below title: a horizontal scrollable flow diagram with 5 connected step indicators
  - Each step is a small rounded rectangle (70px wide, 60px tall) with icon on top and label below
  - Steps connected by thin gray arrow lines (→) between them
  - Step 1: generator icon + "Generator" label, light blue bg (#E3F2FD)
  - Step 2: calculator icon + "QoS Factor" label, light green bg (#E8F5E9)
  - Step 3: brain/logic icon + "Fuzzy" label, light orange bg (#FFF3E0)
  - Step 4: ranking icon + "TOPSIS" label, light purple bg (#F3E5F5)
  - Step 5: checkmark icon + "Evaluasi" label, light teal bg (#E0F2F1)

SECTION 3 — Menu Utama (20px below flow diagram):
- Section title: "Menu Utama" bold, size 15px, dark, 16px from left, with small blue dot before text
- 12px below: 2-column grid, 12px gap, 16px margin left/right
- 6 cards total (2 columns x 3 rows), each card:
  - White background, rounded 12px, subtle shadow, height 110px, padding 16px
  - Top-left: colored circle icon container (40px diameter)
  - Below icon (10px gap): bold title text size 14px, dark
  - Below title (4px gap): description text size 11px, gray (#757575)

  Card details:
  - Card 1: Blue play icon on light blue circle. Title: "Simulasi Baru". Desc: "Jalankan skenario eksperimen"
  - Card 2: Orange sliders icon on light orange circle. Title: "Konfigurasi". Desc: "Atur Fuzzy, TOPSIS, bobot"
  - Card 3: Green list icon on light green circle. Title: "Log Keputusan". Desc: "Riwayat handover lengkap"
  - Card 4: Purple chart icon on light purple circle. Title: "Metrik & Grafik". Desc: "Evaluasi performa"
  - Card 5: Teal compare icon on light teal circle. Title: "Komparasi". Desc: "Fuzzy-TOPSIS vs Baseline"
  - Card 6: Red download icon on light red circle. Title: "Ekspor Data". Desc: "JSON / CSV"

BOTTOM — Navigation Bar (height 64px, white background, subtle top border line #E0E0E0):
- 4 equally spaced items, each with icon above and label below (size 11px):
  - Item 1: home filled icon + "Beranda" in blue (#1565C0) — ACTIVE state
  - Item 2: science/flask icon + "Simulasi" in gray (#9E9E9E) — inactive
  - Item 3: analytics icon + "Hasil" in gray (#9E9E9E) — inactive
  - Item 4: settings icon + "Pengaturan" in gray (#9E9E9E) — inactive
```

---

## PROMPT 3 — Konfigurasi Eksperimen

```
Design a mobile app experiment configuration screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame. This is a scrollable screen.

TOP — App Bar (height 56px, white background, subtle shadow):
- Left: back arrow icon (←) in dark gray (#616161), 16px from left
- Center: title "Konfigurasi Eksperimen" bold, size 18px, dark (#212121)
- Right: info circle icon (ⓘ) in gray, 16px from right

SECTION 1 — "Skenario Kecepatan" (16px margin left/right, 16px below app bar):
- Section header: bold text "Skenario Kecepatan" size 15px, dark, with vertical blue accent bar (3px wide, 18px tall) on the left side
- Helper text below (4px gap): "Pilih kecepatan pengguna yang akan diuji (m/s)" in gray (#757575), size 12px
- 12px below: horizontal row of 5 selectable chip buttons, 8px gap between each:
  - Chip "1": rounded pill, blue filled (#1565C0), white text — SELECTED
  - Chip "5": rounded pill, blue filled (#1565C0), white text — SELECTED
  - Chip "10": rounded pill, blue filled (#1565C0), white text — SELECTED
  - Chip "20": rounded pill, blue filled (#1565C0), white text — SELECTED
  - Chip "30": rounded pill, blue filled (#1565C0), white text — SELECTED
- 8px below chips: small text "+ Tambah kecepatan lain" in blue, size 12px, with plus icon

SECTION 2 — "Kelas Aplikasi" (24px below Section 1):
- Section header: bold text "Kelas Aplikasi" size 15px, with blue accent bar
- Helper text: "Kelas trafik yang akan disimulasikan" in gray, size 12px
- 12px below: 4 toggle items in vertical list, each item is a row (height 48px):
  - Row has: left colored dot indicator, text label in middle, toggle switch on right
  - Row 1: green dot + "Conversational" + toggle ON (blue)
  - Row 2: orange dot + "Streaming" + toggle ON (blue)
  - Row 3: purple dot + "Interactive" + toggle ON (blue)
  - Row 4: gray dot + "Background" + toggle ON (blue)

SECTION 3 — "Pengulangan & Seed" (24px below Section 2):
- Section header: bold text "Pengulangan & Seed" size 15px, with blue accent bar
- Helper text: "Minimal 3 seed berbeda per kombinasi (PRD Section 6)" in gray, size 12px
- 12px below: Material Design outlined text field
  - Label: "Jumlah Seed (Pengulangan)" floating above
  - Value: "3"
  - Full width, height 56px, rounded 8px, gray border
- 12px below: another text field
  - Label: "Daftar Seed" floating above
  - Value: "42, 123, 456"
  - Full width, height 56px
  - Helper text below: "Pisahkan dengan koma. Seed sama = hasil identik (FR-03)" size 11px, gray

SECTION 4 — "Interval Evaluasi" (24px below Section 3):
- Section header: bold text "Interval Evaluasi" size 15px, with blue accent bar
- 12px below: two selectable option cards side by side (2 columns, 12px gap):
  - Card 1 (SELECTED): blue border (2px), white bg, rounded 12px, height 72px
    - Bold "1 detik" size 16px, blue color, centered
    - Below: "Default (PRD)" size 11px, gray
    - Small blue checkmark icon top-right corner
  - Card 2 (unselected): gray border (1px), white bg, rounded 12px, height 72px
    - Bold "5 detik" size 16px, dark color, centered
    - Below: "Variasi tambahan" size 11px, gray

SECTION 5 — "Jumlah Langkah Simulasi" (24px below Section 4):
- Section header: bold text "Jumlah Langkah" size 15px, with blue accent bar
- 12px below: Material Design outlined text field
  - Label: "Langkah per skenario"
  - Value: "100"
  - Helper text: "Tiap langkah = 1 interval evaluasi" size 11px

SECTION 6 — "Metode Pembanding" (24px below Section 5):
- Section header: bold text "Metode Pembanding" size 15px, with blue accent bar
- Helper text: "Baseline berjalan pada skenario & seed yang sama (FR-09)" gray, size 12px
- 12px below: single info card, light yellow background (#FFFDE7), rounded 12px, padding 16px:
  - Left: info icon in amber color
  - Text: "Baseline: RSS-Only — Memilih jaringan tersedia dengan RSS tertinggi. Aturan deterministik saat RSS sama." in dark text, size 13px

BOTTOM — fixed at bottom, 16px margin, 16px from bottom edge:
- Full width rounded button (height 52px, rounded 26px, blue #1565C0 background):
  - Text: "Lanjut ke Konfigurasi Fuzzy →" bold white, size 15px, centered
```

---

## PROMPT 4 — Konfigurasi Fuzzy & Ambang

```
Design a mobile app Fuzzy Logic configuration screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame. Scrollable screen.

TOP — App Bar (height 56px, white, shadow):
- Left: back arrow (←) dark gray
- Center: "Konfigurasi Fuzzy" bold, 18px, dark
- Right: text "2/3" in gray (step indicator), size 13px

SECTION 1 — "Input Fuzzy Logic" (16px margin, 16px below app bar):
- Section header: "Input Fuzzy Logic (FR-05)" bold, 15px, with blue accent bar left
- Helper text: "Tiga input: QoS Factor, RSS, dan Kecepatan → Output: Handover Factor (0–1)" gray, 12px

- 12px below: a visual diagram box (full width, height 140px, light gray bg #F5F5F5, rounded 12px, padding 16px):
  - Left column "INPUT" label in small caps gray:
    - 3 small rounded boxes stacked vertically (8px gap):
      - Box 1: green bg, white text "QoS Factor"
      - Box 2: blue bg, white text "RSS (dBm)"
      - Box 3: orange bg, white text "Velocity (m/s)"
  - Center: large box with brain icon, text "Fuzzy Inference" on dark navy bg, white text
  - Right column "OUTPUT" label:
    - 1 box: red/coral bg, white text "Handover Factor"
  - Gray arrow lines connecting left boxes → center → right box

SECTION 2 — "QoS Factor Formula" (24px below):
- Section header: "Rumus QoS Factor (FR-04)" bold, 15px, with blue accent bar
- Helper text: "Dihitung dari Data Rate, Delay, dan BER sesuai kelas aplikasi" gray, 12px
- 12px below: a formula display card (white bg, rounded 12px, subtle shadow, padding 16px):
  - Centered monospace text: "QoS = w₁·norm(DataRate) + w₂·norm(1/Delay) + w₃·norm(1/BER)" size 13px, dark
  - Below (8px): small text "Bobot (w₁, w₂, w₃) berbeda per kelas aplikasi → lihat halaman Profil Bobot" gray italic, 11px

SECTION 3 — "Ambang Inisiasi per Kelas (FR-06)" (24px below):
- Section header: "Ambang Handover per Kelas Aplikasi" bold, 15px, with blue accent bar
- Helper text: "Handover factor harus melewati ambang ini agar TOPSIS berjalan. Nilai 0–1." gray, 12px

- 12px below: 4 slider rows, each row (height 72px) containing:
  - Left: colored label tag (rounded pill, 12px padding)
  - Center: horizontal slider with current value tooltip above thumb
  - Right: value display text, bold

  - Row 1:
    - Green pill label "Conversational"
    - Slider track: gray bg, green filled portion, thumb at position 0.70
    - Value: "0.70" bold green text
    
  - Row 2:
    - Orange pill label "Streaming"
    - Slider: orange filled, thumb at 0.65
    - Value: "0.65" bold orange
    
  - Row 3:
    - Purple pill label "Interactive"
    - Slider: purple filled, thumb at 0.60
    - Value: "0.60" bold purple
    
  - Row 4:
    - Gray pill label "Background"
    - Slider: gray filled, thumb at 0.50
    - Value: "0.50" bold dark gray

- 8px below sliders: small info box (light blue bg #E3F2FD, rounded 8px, padding 10px):
  - Text: "Nilai 0.7 dari rancangan paper belum divalidasi — ditandai sebagai asumsi tim" blue, 11px, with info icon

SECTION 4 — "Fungsi Keanggotaan" (24px below):
- Section header: "Fungsi Keanggotaan Fuzzy" bold, 15px, with blue accent bar
- Helper text: "Gaussian membership function untuk setiap variabel input" gray, 12px

- 12px below: 3 small preview cards in vertical list, each (height 80px, white bg, rounded 12px, shadow, padding 12px):
  - Card 1: left icon "QoS" on green circle, center text "QoS Factor" bold 14px + "Low, Medium, High" gray 12px, right: chevron arrow (→)
  - Card 2: left icon "RSS" on blue circle, center text "RSS (dBm)" bold + "Weak, Medium, Strong" gray, right: chevron (→)
  - Card 3: left icon "v" on orange circle, center text "Kecepatan (m/s)" bold + "Slow, Medium, Fast" gray, right: chevron (→)

  - Each card is tappable to see/edit membership function detail

BOTTOM — fixed button:
- Full width, rounded 26px, blue (#1565C0), height 52px
- Text: "Lanjut ke Profil Bobot TOPSIS →" bold white, 15px
```

---

## PROMPT 5 — Profil Bobot TOPSIS per Kelas Aplikasi

```
Design a mobile app TOPSIS weight profile configuration screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame. Scrollable.

TOP — App Bar (height 56px):
- Left: back arrow (←) dark gray
- Center: "Profil Bobot TOPSIS" bold, 18px
- Right: text "3/3" gray, 13px

INFO BANNER (16px margin, 8px below app bar):
- Full width card, light blue bg (#E3F2FD), rounded 12px, padding 14px:
  - Row 1: bold text "Kriteria Seleksi TOPSIS (FR-07)" dark, 14px
  - Row 2 (4px below): "Data Rate (benefit) · Delay (cost) · BER (cost)" gray, 12px
  - Row 3 (4px below): "Jumlah bobot setiap kelas harus = 1.00 (FR-08)" blue bold, 12px

SECTION 1 — "Conversational" (16px margin, 16px below banner):
- Expandable card, EXPANDED state:
  - Header: green left border (4px), white bg, rounded top 12px, height 52px
    - Left: green dot + bold "Conversational" 15px dark
    - Right: upward chevron (▲) + text "Σ = 1.00" green bold 13px
  - Body: white bg, rounded bottom 12px, padding 16px, subtle shadow
    - 3 parameter rows, each row has:
      - Label left (13px gray)
      - Horizontal slider in the middle
      - Value right (bold, 14px)
      
    - Row 1: "Data Rate (w₁)" | slider thumb at 0.20 position, blue fill | "0.20"
    - Row 2: "Delay (w₂)" | slider thumb at 0.50 position, blue fill | "0.50"
    - Row 3: "BER (w₃)" | slider thumb at 0.30 position, blue fill | "0.30"
    
    - 12px below sliders: a small horizontal stacked bar chart (full width, height 24px, rounded 12px):
      - Segment 1: blue, width 20% of bar, label "DR 20%"
      - Segment 2: orange, width 50%, label "DL 50%"
      - Segment 3: red, width 30%, label "BER 30%"
    
    - 8px below bar: italic text "Prioritas: Delay > BER > Data Rate (panggilan suara membutuhkan latensi rendah)" gray, 11px

SECTION 2 — "Streaming" (12px below Section 1):
- Expandable card, COLLAPSED state:
  - Header only: orange left border, white bg, rounded 12px, height 52px
    - Left: orange dot + bold "Streaming" 15px
    - Right: chevron (▼) + "Σ = 1.00" dark 13px
    - Subtitle below title inside header: "w₁=0.50, w₂=0.30, w₃=0.20" gray 12px

SECTION 3 — "Interactive" (12px below):
- Collapsed card:
  - Purple left border, "Interactive", "w₁=0.40, w₂=0.35, w₃=0.25"

SECTION 4 — "Background" (12px below):
- Collapsed card:
  - Gray left border, "Background", "w₁=0.60, w₂=0.20, w₃=0.20"

VALIDATION BOX (20px below last card):
- Full width card, rounded 12px, padding 16px:
  - If all valid: light green bg (#E8F5E9), green checkmark icon, text "Semua profil bobot valid dan ternormalisasi ✓" green bold 13px
  - Below (4px): "Bobot dapat ditinjau dan diubah dari konfigurasi (FR-08)" gray 11px

BOTTOM — fixed button:
- Full width, rounded 26px, green (#2E7D32), height 52px
- Text: "Mulai Simulasi ▶" bold white, 16px
```

---

## PROMPT 6 — Monitor Simulasi (Running)

```
Design a mobile app simulation monitor screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). Dark background (#121212) for a monitoring/console feel. No device frame.

TOP — App Bar (height 56px, dark bg #1E1E1E):
- Left: close icon (✕) in white
- Center: "Simulasi Berjalan" bold white, 18px
- Right: small pulsing green dot (8px) + text "LIVE" in green (#4CAF50), 12px

SECTION 1 — Progress Overview (16px margin, 12px below app bar):
- Dark card (#1E1E1E), rounded 16px, padding 16px
  - Row 1: "Skenario" label gray 12px, value "Streaming · 10 m/s · Seed 42" white bold 14px
  - Row 2 (8px below): "Metode" gray 12px, value "Fuzzy-TOPSIS" white 14px + small blue chip "+ Baseline RSS" next to it
  - 12px below rows:
    - Thin progress bar (full width, height 8px, rounded 4px): 
      - Background: dark gray (#333333)
      - Fill: blue (#42A5F5), filled to about 65%
    - Below bar (4px): left text "Langkah 65/100" white 12px, right text "65%" white 12px

SECTION 2 — Live Network Status (16px below):
- Section title: "Kondisi Jaringan (t = 65s)" in white bold 14px
- 12px below: 3 horizontal network status cards in a row (3 columns, 8px gap):
  - Each card: dark card (#1E1E1E), rounded 12px, height 100px, padding 10px
  
  - Card "4G":
    - Top: "4G" bold white 14px + small green dot "OK" 
    - RSS: "-98.5" white, "dBm" gray 10px
    - Rate: "45.2" white, "Mbps" gray 10px
    - Thin colored bar at bottom: green fill (signal quality indicator)
    
  - Card "5G":
    - Top: "5G" bold white 14px + small green dot "OK"
    - RSS: "-82.1" white, "dBm" gray
    - Rate: "612.4" white, "Mbps" gray
    - Bottom bar: bright green (strong signal)
    
  - Card "WLAN":
    - Top: "WLAN" bold white 14px + small red dot "OUT"
    - RSS: "-95.3" white, "dBm" gray
    - Rate: "—" white
    - Bottom bar: red (out of range)

SECTION 3 — Current Decision (16px below):
- Dark card (#1E1E1E) with left border green (4px), rounded 12px, padding 16px
  - Line 1: "Keputusan Saat Ini" gray 12px uppercase
  - Line 2: "QoS Factor = 0.42" white 14px
  - Line 3: "Handover Factor = 0.73" white 14px + yellow pill badge "Di atas ambang 0.65"
  - Line 4 (8px below): large bold text "HANDOVER → 5G (nr_1)" in green (#4CAF50), 18px
  - Line 5: "TOPSIS Scores: 5G=0.82, 4G=0.61" in gray 12px

SECTION 4 — Live Log Feed (16px below):
- Section title: "Log Terbaru" white bold 14px, right side: "Lihat Semua →" blue 12px
- 8px below: scrollable dark area (#0D1117), rounded 12px, height 160px, padding 12px, monospace font:
  - Log line 1: green text "[t=65] HANDOVER lte_1 → nr_1 | HF=0.73 | TOPSIS: nr_1(0.82)" size 11px
  - Log line 2: white text "[t=64] STAY lte_1 | HF=0.41 | below threshold 0.65" size 11px
  - Log line 3: white text "[t=63] STAY lte_1 | HF=0.38 | below threshold 0.65" size 11px
  - Log line 4: yellow text "[t=62] WARNING wlan_1 out of range" size 11px
  - Log line 5: green text "[t=61] HANDOVER nr_1 → lte_1 | HF=0.71 | TOPSIS: lte_1(0.75)" size 11px

BOTTOM — fixed row (16px margin, 16px from bottom):
- Two buttons side by side (12px gap):
  - Left button (48% width): outlined, red border, rounded 26px, height 48px
    - Text: "Hentikan" red, 14px, with stop icon
  - Right button (48% width): filled blue (#42A5F5), rounded 26px, height 48px
    - Text: "Baseline ✓" white, 14px (indicating baseline running in parallel)
```

---

## PROMPT 7 — Log Keputusan

```
Design a mobile app decision log screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame.

TOP — App Bar (height 56px, white, shadow):
- Left: back arrow (←) dark gray
- Center: "Log Keputusan" bold, 18px, dark
- Right: filter funnel icon in gray

FILTER BAR (directly below app bar, height 44px, light gray bg #F5F5F5):
- Horizontal scrollable row of filter chip buttons, 8px gap, 16px margin left:
  - Chip "Semua" blue filled — ACTIVE
  - Chip "Handover" outlined gray
  - Chip "Stay" outlined gray
  - Chip "Failed" outlined gray
- Right end: text "247 entri" gray 12px

LOG ENTRIES — Vertical list of decision cards, 16px margin left/right, 8px gap between cards:

- Entry Card 1 (HANDOVER — expanded detail):
  - White card, rounded 12px, subtle shadow, green left border (4px)
  - Header row (height 48px, padding 12px):
    - Left: green badge "HANDOVER" (rounded pill, green bg, white text, 11px bold)
    - Center: "t = 65s" dark bold 14px
    - Right: chevron up (▲) indicating expanded
  
  - Expanded body (padding 12px, light gray bg #FAFAFA, 1px top border):
    - Two-column key-value layout, each row 24px height:
      - Row 1: "Posisi" gray 12px → "(650.0, 0.0) m" dark 12px
      - Row 2: "Kecepatan" gray → "10.0 m/s" dark
      - Row 3: "Kelas Aplikasi" gray → "Streaming" orange pill badge
      - Row 4: "Jaringan Asal" gray → "lte_1 (4G)" dark
      - Row 5: "QoS Factor" gray → "0.42" dark
      - Row 6: "Handover Factor" gray → "0.73" dark bold
      - Row 7: "Ambang" gray → "0.65" dark
      - Row 8: "Status Ambang" gray → "Di atas ambang ✓" green bold
    
    - Divider line (1px gray, full width, 8px margin top/bottom)
    
    - Sub-section "Kandidat & Skor TOPSIS":
      - Mini table, 3 rows:
        - Header: "Kandidat" | "Data Rate" | "Delay" | "BER" | "Skor" (gray, 11px)
        - Row 1: "nr_1 (5G)" | "612.4" | "8.2" | "1.3e-7" | "0.82" — highlighted row with light green bg
        - Row 2: "wlan_1 (WLAN)" | "—" | "—" | "—" | "N/A" — grayed out with "OUT" red text
      
    - 8px below table:
      - "Keputusan: lte_1 → nr_1" bold dark 14px, green left arrow icon
      - "Alasan: Handover factor (0.73) melewati ambang (0.65); nr_1 memiliki skor TOPSIS tertinggi" gray 12px

- Entry Card 2 (STAY — collapsed):
  - White card, rounded 12px, gray left border (4px)
  - Single row (height 48px, padding 12px):
    - Left: gray badge "STAY" (gray bg, dark text, 11px)
    - Center: "t = 64s" dark 14px + "lte_1 (4G)" gray 12px
    - Right: "HF=0.41" gray 12px + chevron down (▼)

- Entry Card 3 (STAY — collapsed):
  - Same as Card 2 but "t = 63s", "HF=0.38"

- Entry Card 4 (FAILED — collapsed):
  - White card, rounded 12px, red left border (4px)
  - Single row:
    - Left: red badge "FAILED" (red bg, white text)
    - Center: "t = 58s" dark + "nr_1 → wlan_1" gray
    - Right: "Target unavailable" red 11px + chevron down (▼)

- More cards below (scrollable)...

BOTTOM NAV — same 4 tabs as Home, "Hasil" tab active in blue
```

---

## PROMPT 8 — Hasil Metrik Evaluasi

```
Design a mobile app evaluation metrics dashboard screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame.

TOP — App Bar (height 56px, white, shadow):
- Left: back arrow (←) dark gray
- Center: "Metrik Evaluasi" bold, 18px, dark
- Right: share/export icon gray

SCENARIO SELECTOR (12px below app bar, 16px margin left/right):
- Horizontal scrollable pills:
  - "Streaming · 10 m/s" blue filled — ACTIVE
  - "Conversational · 10 m/s" gray outline
  - "Interactive · 10 m/s" gray outline
  - Small right arrow indicating scroll

SECTION 1 — Metric Summary Cards (16px margin, 12px below selector):
- 2x2 grid of metric cards, 12px gap between cards:

  - Card 1 (top-left): white bg, rounded 16px, shadow, height 120px, padding 16px
    - Top: small icon (checkmark in green circle) + label "Handover Berhasil" gray 12px
    - Center: large bold number "34" dark, size 32px
    - Bottom: small text "dari 38 percobaan" gray 12px
    - Thin green bottom accent bar (4px, full width, rounded)

  - Card 2 (top-right): white bg, rounded 16px, shadow, height 120px
    - Top: small icon (x in red circle) + "Failure Rate" gray 12px
    - Center: large bold "10.5%" dark, size 32px
    - Bottom: "4 gagal / 38 percobaan" gray 12px
    - Thin red bottom accent bar

  - Card 3 (bottom-left): white bg, rounded 16px, shadow, height 120px
    - Top: small icon (refresh arrows in orange circle) + "Ping-Pong Rate" gray 12px
    - Center: large bold "5.9%" dark, size 32px
    - Bottom: "2 ping-pong / 34 berhasil" gray 12px
    - Thin orange bottom accent bar

  - Card 4 (bottom-right): white bg, rounded 16px, shadow, height 120px
    - Top: small icon (warning in yellow circle) + "Unnecessary HO" gray 12px
    - Center: large bold "8.8%" dark, size 32px
    - Bottom: "3 tidak perlu / 34 berhasil" gray 12px
    - Small label "proxy" in yellow pill badge, 10px
    - Thin yellow bottom accent bar

SECTION 2 — Comparison Table (20px below cards):
- Section title: "Perbandingan Metode" bold 15px, with blue dot accent
- 12px below: white card, rounded 12px, shadow, full width, padding 0

  - Table with header and 2 data rows:
    - Header row: light gray bg (#F0F0F0), bold text 12px
      - Columns: "Metrik" | "Fuzzy-TOPSIS" | "Baseline RSS"
    
    - Row 1 (white bg, height 44px):
      - "Handover Berhasil" | "34" bold | "52" bold
    
    - Row 2 (light bg #FAFAFA):
      - "Failure Rate" | "10.5%" green text (lower is better, highlighted) | "15.8%" dark
    
    - Row 3 (white):
      - "Ping-Pong Rate" | "5.9%" green text | "23.1%" dark
    
    - Row 4 (light bg):
      - "Unnecessary HO" | "8.8%" green text | "34.6%" dark

  - Below table (8px): small italic text "Seed: 42, 123, 456 (rata-rata 3 pengulangan)" gray 11px

SECTION 3 — Verdict Card (16px below):
- Card with green left border (4px), light green bg (#E8F5E9), rounded 12px, padding 16px:
  - Bold text "Fuzzy-TOPSIS lebih unggul" dark 16px
  - Below (4px): "Failure rate 33% lebih rendah, ping-pong rate 74% lebih rendah dibanding baseline RSS-only" dark 13px

BOTTOM NAV — "Hasil" tab active
```

---

## PROMPT 9 — Grafik Komparasi

```
Design a mobile app comparison charts screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame. Scrollable.

TOP — App Bar (height 56px):
- Left: back arrow (←) dark gray
- Center: "Grafik Komparasi" bold, 18px, dark
- Right: download icon gray

TAB BAR (below app bar, height 44px, white bg):
- 3 tabs equally spaced:
  - "Per Kecepatan" blue underline — ACTIVE
  - "Per Kelas" gray — inactive
  - "Timeline" gray — inactive

LEGEND BAR (8px below tabs, 16px margin, height 32px):
- Centered horizontal row:
  - Blue filled circle (10px) + "Fuzzy-TOPSIS" text 12px dark, 16px gap
  - Red outlined circle (10px) + "Baseline RSS" text 12px dark

CHART 1 — Handover Failure Rate vs Kecepatan (16px margin, 12px below legend):
- White card, rounded 16px, shadow, padding 16px
- Title: "Handover Failure Rate vs Kecepatan" bold 14px dark, left-aligned
- Subtitle: "Kelas: Streaming | Seed rata-rata" gray 11px
- 8px below: grouped bar chart (full width, height 200px):
  - X-axis: "Kecepatan (m/s)" with labels "1", "5", "10", "20", "30"
  - Y-axis: "Failure Rate (%)" with gridlines at 0%, 10%, 20%, 30%, 40%
  - For each x value, 2 bars side by side:
    - Blue bar (Fuzzy-TOPSIS): heights approximately 2%, 5%, 10%, 15%, 22%
    - Red bar (Baseline RSS): heights approximately 5%, 12%, 18%, 28%, 38%
  - Thin horizontal gray gridlines
  - Blue bars consistently lower than red bars

CHART 2 — Ping-Pong Rate vs Kecepatan (16px below chart 1):
- White card, rounded 16px, shadow, padding 16px
- Title: "Ping-Pong Rate vs Kecepatan" bold 14px
- Subtitle: "Kelas: Streaming | Seed rata-rata"
- Line chart (full width, height 200px):
  - X-axis: "Kecepatan (m/s)" labels 1, 5, 10, 20, 30
  - Y-axis: "Ping-Pong Rate (%)" gridlines at 0%, 10%, 20%, 30%
  - Blue solid line with circle markers (Fuzzy-TOPSIS): relatively flat, values around 3-8%
  - Red dashed line with square markers (Baseline RSS): rising steeply, values 5%, 10%, 18%, 25%, 32%
  - Data point tooltips not shown in wireframe
  - Light blue shaded area under blue line (subtle fill)

CHART 3 — Unnecessary Handover vs Kecepatan (16px below chart 2):
- White card, rounded 16px, shadow, padding 16px
- Title: "Unnecessary Handover (Proxy) vs Kecepatan" bold 14px
- Subtitle: "Kelas: Streaming | Seed rata-rata"
- Grouped bar chart (full width, height 200px):
  - Same x-axis as Chart 1
  - Y-axis: "Unnecessary HO (%)" gridlines 0%, 10%, 20%, 30%, 40%, 50%
  - Blue bars (Fuzzy-TOPSIS): approximately 5%, 6%, 9%, 11%, 14%
  - Red bars (Baseline RSS): approximately 20%, 25%, 30%, 38%, 45%

BOTTOM (16px below Chart 3, 16px margin):
- Small info card (light yellow bg #FFFDE7, rounded 8px, padding 12px):
  - Info icon amber + text "Data sintetis — bukan hasil pengukuran jaringan nyata (PRD Bagian 1)" dark 12px

BOTTOM NAV — "Hasil" tab active
```

---

## PROMPT 10 — Ekspor Data

```
Design a mobile app data export screen wireframe in flat Material Design 3 style (9:16 portrait, 390x844px). White background (#FAFAFA). No device frame.

TOP — App Bar (height 56px):
- Left: back arrow (←) dark gray
- Center: "Ekspor Data" bold, 18px, dark
- Right: none

SECTION 1 — "Pilih Data" (16px margin, 16px below app bar):
- Section header: "Pilih Data untuk Diekspor" bold 15px, with blue accent bar

- 12px below: vertical list of selectable items, each is a card row (height 64px, white bg, rounded 12px, shadow, 8px gap between cards):

  - Item 1: 
    - Left: blue checkbox (checked ✓)
    - Icon: document list icon, blue circle bg
    - Text: bold "Log Keputusan Lengkap" 14px dark
    - Subtitle: "247 entri · Waktu, posisi, QoS, HF, TOPSIS, keputusan" 11px gray
    - Right: file size "~125 KB" gray 11px

  - Item 2:
    - Left: blue checkbox (checked ✓)
    - Icon: bar chart icon, green circle bg
    - Text: bold "Ringkasan Metrik" 14px dark
    - Subtitle: "Failure rate, ping-pong, unnecessary HO per skenario" 11px gray
    - Right: "~8 KB" gray

  - Item 3:
    - Left: blue checkbox (checked ✓)
    - Icon: table grid icon, orange circle bg
    - Text: bold "Profil Jaringan (Snapshot)" 14px dark
    - Subtitle: "RSS, Data Rate, Delay, BER tiap timestep" 11px gray
    - Right: "~340 KB" gray

  - Item 4:
    - Left: gray checkbox (unchecked)
    - Icon: settings icon, purple circle bg
    - Text: bold "Konfigurasi Eksperimen" 14px dark
    - Subtitle: "Bobot, ambang, seed, parameter Fuzzy" 11px gray
    - Right: "~2 KB" gray

SECTION 2 — "Format Ekspor" (24px below):
- Section header: "Format File" bold 15px, with blue accent bar

- 12px below: 2 option cards side by side (2 columns, 12px gap):
  - Card 1 (SELECTED): blue border (2px), white bg, rounded 16px, height 100px, center-aligned content
    - Large icon: "{ }" curly braces in blue, 32px
    - Below: bold "JSON" 16px blue
    - Below: "Terstruktur, mudah diproses" 11px gray
    - Blue checkmark badge top-right
    
  - Card 2 (unselected): gray border (1px), white bg, rounded 16px, height 100px
    - Large icon: table/grid icon in gray, 32px
    - Below: bold "CSV" 16px dark
    - Below: "Kompatibel spreadsheet" 11px gray

SECTION 3 — "Pratinjau" (24px below):
- Section header: "Pratinjau Data" bold 15px, with blue accent bar

- 12px below: dark code preview card (#1E1E1E), rounded 12px, height 160px, padding 12px:
  - Monospace text, syntax highlighted:
    ```
    {
      "scenario": "streaming_10mps_seed42",
      "method": "fuzzy_topsis",
      "steps": 100,
      "metrics": {
        "handover_success": 34,
        "failure_rate": 0.105,
        "pingpong_rate": 0.059,
        "unnecessary_ho_proxy": 0.088
      },
      "log": [ ... ]
    }
    ```
  - All text in green/white monospace, size 11px
  - Bottom-right of card: "Scroll untuk lihat lebih" gray italic 10px

BOTTOM — fixed, 16px margin, 16px from bottom:
- Full width button, rounded 26px, blue (#1565C0), height 52px:
  - Download icon white + text "Ekspor 3 File (473 KB)" bold white 15px
- 8px below button: text "File akan disimpan di folder Download" gray centered 11px

BOTTOM NAV — "Pengaturan" tab active
```

---

## Rangkuman Alur Navigasi Seluruh Halaman

```
Splash Screen
    ↓
Home Dashboard
    ├── Simulasi Baru → Konfigurasi Eksperimen → Konfigurasi Fuzzy → Profil Bobot TOPSIS → Monitor Simulasi
    ├── Log Keputusan → Log Keputusan (detail expandable)
    ├── Metrik & Grafik → Hasil Metrik Evaluasi
    ├── Komparasi → Grafik Komparasi (per kecepatan / per kelas / timeline)
    └── Ekspor Data → Ekspor Data (JSON / CSV)
```
