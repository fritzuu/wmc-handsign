import 'package:flutter/material.dart';
import '../handover/configuration.dart';
import '../handover/models.dart';

/// Spesifikasi kebutuhan QoS / SLA untuk aplikasi tertentu.
///
/// Mengacu pada standar 3GPP TS 23.501, ITU-T G.1010, dan ITU-T G.114.
class AppQosRequirement {
  final double minDataRateMbps;
  final double targetDataRateMbps;
  final double maxDelayMs;
  final double targetDelayMs;
  final double maxBer;
  final double targetBer;

  const AppQosRequirement({
    required this.minDataRateMbps,
    required this.targetDataRateMbps,
    required this.maxDelayMs,
    required this.targetDelayMs,
    required this.maxBer,
    this.targetBer = 1e-7,
  }) : assert(minDataRateMbps >= 0, 'minDataRateMbps tidak boleh negatif'),
       assert(targetDataRateMbps >= minDataRateMbps, 'targetDataRateMbps harus >= minDataRateMbps'),
       assert(maxDelayMs >= 0, 'maxDelayMs tidak boleh negatif'),
       assert(targetDelayMs <= maxDelayMs, 'targetDelayMs harus <= maxDelayMs'),
       assert(maxBer >= 0 && maxBer <= 1.0, 'maxBer harus dalam rentang [0, 1]'),
       assert(targetBer <= maxBer, 'targetBer harus <= maxBer');

  AppQosRequirement copyWith({
    double? minDataRateMbps,
    double? targetDataRateMbps,
    double? maxDelayMs,
    double? targetDelayMs,
    double? maxBer,
    double? targetBer,
  }) {
    return AppQosRequirement(
      minDataRateMbps: minDataRateMbps ?? this.minDataRateMbps,
      targetDataRateMbps: targetDataRateMbps ?? this.targetDataRateMbps,
      maxDelayMs: maxDelayMs ?? this.maxDelayMs,
      targetDelayMs: targetDelayMs ?? this.targetDelayMs,
      maxBer: maxBer ?? this.maxBer,
      targetBer: targetBer ?? this.targetBer,
    );
  }
}

/// Model profil aplikasi spesifik yang memetakan kebutuhan aplikasi ke kelas trafik dan bobot AHP.
class AppProfile {
  final String id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final TrafficClass trafficClass;
  final AppQosRequirement sla;
  final CriterionWeights? customWeights;
  final double? customThreshold;

  /// Apakah aplikasi ini mengonsumsi kuota data dalam volume masif (misal Video Streaming 4K, Cloud Download).
  /// Sesuai kebijakan 3GPP Wi-Fi Offloading: aplikasi boros kuota memprioritaskan Wi-Fi unmetered
  /// jika kualitas Wi-Fi telah memenuhi standar SLA aplikasi.
  final bool isHeavyDataConsumer;

  const AppProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.trafficClass,
    required this.sla,
    this.customWeights,
    this.customThreshold,
    this.isHeavyDataConsumer = false,
  });

  AppProfile copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    IconData? icon,
    TrafficClass? trafficClass,
    AppQosRequirement? sla,
    CriterionWeights? customWeights,
    double? customThreshold,
    bool? isHeavyDataConsumer,
  }) {
    return AppProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      trafficClass: trafficClass ?? this.trafficClass,
      sla: sla ?? this.sla,
      customWeights: customWeights ?? this.customWeights,
      customThreshold: customThreshold ?? this.customThreshold,
      isHeavyDataConsumer: isHeavyDataConsumer ?? this.isHeavyDataConsumer,
    );
  }

  /// Rujukan standar internasional telekomunikasi resmi (3GPP / ITU-T)
  String get standardReference {
    switch (id) {
      case 'youtube':
        return '3GPP TS 23.501 (5QI 4) & ITU-T G.1010 (Streaming)';
      case 'mobile_legends':
        return '3GPP TS 23.501 (5QI 3) & ITU-T G.1010 (Gaming)';
      case 'whatsapp_call':
        return 'ITU-T G.114 / G.107 & 3GPP TS 23.501 (5QI 1)';
      case 'cloud_download':
        return '3GPP TS 23.501 (5QI 9) & ITU-T G.1010 (Bulk Transfer)';
      case 'social_media':
        return '3GPP TS 23.501 (5QI 8) & ITU-T G.1010 (Interactive Data)';
      default:
        return 'Kustom Pengguna / ITU-T G.1010 General';
    }
  }

  /// Penjelasan ilmiah mengapa profil aplikasi ini memiliki spesifikasi SLA unik
  String get technicalRationale {
    switch (id) {
      case 'youtube':
        return 'Memakai protokol TCP dengan buffer adaptif. Latensi wajar (200-350ms) masih ditoleransi karena adanya video pre-fetch buffer, namun mutlak membutuhkan throughput stabil (min 5.0 Mbps untuk 1080p, 25 Mbps untuk 4K) agar tidak terjadi buffering stuttering.';
      case 'mobile_legends':
        return 'Menggunakan transmisi UDP real-time sinkron dua arah. Throughput yang dibutuhkan relatif kecil (~1-5 Mbps), namun latensi di atas 60ms langsung memicu delay input skill dan desinkronisasi karakter (lag spike). Packet loss harus sangat minim (< 10⁻⁵).';
      case 'whatsapp_call':
        return 'Komunikasi suara & video dua arah manusia (ITU-T G.114). Delay transmisi melebihi 150ms menyebabkan tabrakan bicara (talker collision). Sangat sensitif terhadap jitter dan packet drop yang membuat suara pecah atau terputus.';
      case 'cloud_download':
        return 'Transfer berkas asinkron (Background). Sangat toleran terhadap delay tinggi (hingga 800ms), namun membutuhkan bandwidth sebesar mungkin (hingga 100 Mbps) untuk meminimalkan durasi unduh berkas.';
      case 'social_media':
        return 'Trafik interaktif campuran (teks, gambar, video singkat). Memerlukan kompromi latensi yang wajar (<200ms) untuk responsivitas interaksi feed dan bandwidth sedang (~15 Mbps) untuk preload aset media.';
      default:
        return 'Parameter kustom dapat disesuaikan untuk eksperimen skenario trafik khusus.';
    }
  }
}

/// Katalog bawaan profil aplikasi yang siap pakai.
class AppCatalog {
  static const List<AppProfile> defaultProfiles = [
    AppProfile(
      id: 'youtube',
      name: 'YouTube / Video Streaming',
      category: 'Video Streaming',
      description: 'Prioritas throughput tinggi untuk video HD/4K bebas buffering.',
      icon: Icons.play_circle_outline,
      trafficClass: TrafficClass.streaming,
      isHeavyDataConsumer: true,
      sla: AppQosRequirement(
        minDataRateMbps: 5.0,
        targetDataRateMbps: 25.0,
        maxDelayMs: 350.0,
        targetDelayMs: 100.0,
        maxBer: 1e-4,
        targetBer: 1e-6,
      ),
    ),
    AppProfile(
      id: 'mobile_legends',
      name: 'Mobile Legends / Game Online',
      category: 'Online Gaming',
      description: 'Prioritas latensi super rendah (<50ms) dan kestabilan bebas packet loss.',
      icon: Icons.sports_esports_outlined,
      trafficClass: TrafficClass.interactive,
      isHeavyDataConsumer: false,
      sla: AppQosRequirement(
        minDataRateMbps: 1.0,
        targetDataRateMbps: 5.0,
        maxDelayMs: 60.0,
        targetDelayMs: 20.0,
        maxBer: 1e-5,
        targetBer: 1e-7,
      ),
    ),
    AppProfile(
      id: 'whatsapp_call',
      name: 'WhatsApp Call / Zoom VoIP',
      category: 'Voice & Video Call',
      description: 'Prioritas latensi rendah dan transmisi dua arah stabil tanpa jitter.',
      icon: Icons.call_outlined,
      trafficClass: TrafficClass.conversational,
      isHeavyDataConsumer: false,
      sla: AppQosRequirement(
        minDataRateMbps: 0.2,
        targetDataRateMbps: 2.0,
        maxDelayMs: 120.0,
        targetDelayMs: 50.0,
        maxBer: 1e-4,
        targetBer: 1e-6,
      ),
    ),
    AppProfile(
      id: 'cloud_download',
      name: 'Google Drive / Download File',
      category: 'Cloud & Bulk Transfer',
      description: 'Prioritas kecepatan unduh maksimal, toleran terhadap delay tinggi.',
      icon: Icons.cloud_download_outlined,
      trafficClass: TrafficClass.background,
      isHeavyDataConsumer: true,
      sla: AppQosRequirement(
        minDataRateMbps: 10.0,
        targetDataRateMbps: 100.0,
        maxDelayMs: 800.0,
        targetDelayMs: 300.0,
        maxBer: 1e-3,
        targetBer: 1e-5,
      ),
    ),
    AppProfile(
      id: 'social_media',
      name: 'Instagram / Web Browsing',
      category: 'Social Media & Web',
      description: 'Trafik interaktif responsif untuk memuat gambar dan feed konten.',
      icon: Icons.public_outlined,
      trafficClass: TrafficClass.interactive,
      sla: AppQosRequirement(
        minDataRateMbps: 2.0,
        targetDataRateMbps: 15.0,
        maxDelayMs: 200.0,
        targetDelayMs: 80.0,
        maxBer: 1e-4,
        targetBer: 1e-6,
      ),
    ),
    AppProfile(
      id: 'custom',
      name: 'Aplikasi Kustom / Riset Bebas',
      category: 'Custom Profile',
      description: 'Pengaturan bebas untuk eksperimen skenario kustom.',
      icon: Icons.tune,
      trafficClass: TrafficClass.streaming,
      sla: AppQosRequirement(
        minDataRateMbps: 5.0,
        targetDataRateMbps: 20.0,
        maxDelayMs: 250.0,
        targetDelayMs: 100.0,
        maxBer: 1e-4,
        targetBer: 1e-6,
      ),
    ),
  ];

  static AppProfile getById(String id) {
    return defaultProfiles.firstWhere(
      (p) => p.id == id,
      orElse: () => defaultProfiles.first,
    );
  }
}
