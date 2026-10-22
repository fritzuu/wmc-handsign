# WMC Handsign — Mobile Application

Modul aplikasi Flutter untuk sistem rekomendasi vertical handover (VHO) heterogen (WLAN, 4G, 5G).

## Struktur Modul

- `android/` : Native Android build files, manifest, dan integrasi sensor jaringan.
- `ios/`, `web/`, `windows/`, `macos/`, `linux/` : Target runner platform lainnya.
- `lib/` :
  - `core/` : Decision engine (FIS Mamdani, TOPSIS, stabilizers, baseline).
  - `screens/` : Antarmuka pengguna (Dashboard, Monitor, Log, Hasil, Pengaturan).
  - `router/` : Navigasi GoRouter.
  - `theme/` : Tema monokromatik dan konfigurasi UI.
- `test/` : Pengujian unit dan integrasi Flutter.
- `test_dart/` : Pengujian logika core murni tanpa ketergantungan Flutter SDK.
- `tool/` : Skrip demo dan utilitas pengembang.

## Cara Menjalankan

```sh
# Instalasi paket
flutter pub get

# Menjalankan seluruh pengujian unit
flutter test

# Menjalankan tes logika core mandiri
dart test_dart/test_core_logic.dart
dart test_dart/test_hybrid_generator.dart

# Menjalankan aplikasi
flutter run
```
