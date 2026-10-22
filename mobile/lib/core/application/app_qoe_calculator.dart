import 'dart:math' as math;
import '../handover/models.dart';
import 'app_profile.dart';

/// Status kesehatan Quality of Experience (QoE) dari sudut pandang pengguna akhir.
enum QoEHealthStatus {
  pristine, // 85 - 100%: Pengalaman luar biasa lancar
  good,     // 70 - 84%: Lancar dengan sedikit latensi
  degraded, // 50 - 69%: Terasa lag / penurunan resolusi
  critical, // < 50%: Stuttering parah / call drop / lag spike
}

/// Telemetri spesifik aplikasi yang mencerminkan performa nyata.
class AppLiveTelemetry {
  final String metricPrimaryLabel;
  final String metricPrimaryValue;
  final String metricSecondaryLabel;
  final String metricSecondaryValue;
  final String statusHighlight;
  final bool isAlertActive;

  const AppLiveTelemetry({
    required this.metricPrimaryLabel,
    required this.metricPrimaryValue,
    required this.metricSecondaryLabel,
    required this.metricSecondaryValue,
    required this.statusHighlight,
    this.isAlertActive = false,
  });
}

/// Hasil kalkulasi Quality of Experience (QoE) lengkap untuk aplikasi aktif.
class QoEEvaluationResult {
  final double score; // 0.0 - 100.0%
  final QoEHealthStatus status;
  final String statusTitle;
  final String statusDescription;
  final AppLiveTelemetry telemetry;
  final double? projectedScoreAfterHandover;
  final String? handoverBenefitText;

  const QoEEvaluationResult({
    required this.score,
    required this.status,
    required this.statusTitle,
    required this.statusDescription,
    required this.telemetry,
    this.projectedScoreAfterHandover,
    this.handoverBenefitText,
  });
}

/// Kalkulator cerdas untuk mengestimasi Quality of Experience (QoE)
/// berdasarkan profil aplikasi spesifik (Gaming, Video Call, Streaming, Download).
class AppQoECalculator {
  const AppQoECalculator();

  /// Menghitung skor QoE real-time dari snapshot jaringan saat ini terhadap profil aplikasi.
  QoEEvaluationResult evaluate({
    required AppProfile appProfile,
    required NetworkSnapshot? activeSnapshot,
    NetworkSnapshot? recommendedSnapshot,
  }) {
    if (activeSnapshot == null || !activeSnapshot.available) {
      return QoEEvaluationResult(
        score: 0.0,
        status: QoEHealthStatus.critical,
        statusTitle: 'KONEKSI TERPUTUS',
        statusDescription: 'Jaringan tidak terdeteksi. Aplikasi mengalami downtime total.',
        telemetry: const AppLiveTelemetry(
          metricPrimaryLabel: 'Status',
          metricPrimaryValue: 'OFFLINE',
          metricSecondaryLabel: 'Loss',
          metricSecondaryValue: '100%',
          statusHighlight: 'Koneksi Terputus Total',
          isAlertActive: true,
        ),
        projectedScoreAfterHandover: recommendedSnapshot?.available == true ? 90.0 : null,
        handoverBenefitText: recommendedSnapshot != null
            ? 'Segera alihkan ke ${recommendedSnapshot.displayName} untuk pulihkan layanan.'
            : null,
      );
    }

    final delay = activeSnapshot.delayMs;
    final dataRate = activeSnapshot.dataRateMbps;
    final ber = activeSnapshot.ber;

    double score = 100.0;
    late AppLiveTelemetry telemetry;
    late String statusTitle;
    late String statusDescription;

    switch (appProfile.id) {
      case 'mobile_legends':
        // --- GAMING ESPORTS QOE ---
        // Penalti latensi sangat ketat (target < 25ms, max 60ms)
        if (delay <= 25.0) {
          score = 95.0 + (25.0 - delay) * 0.2;
        } else if (delay <= 60.0) {
          score = 75.0 + (60.0 - delay) * 0.55;
        } else if (delay <= 120.0) {
          score = 40.0 + (120.0 - delay) * 0.58;
        } else {
          score = math.max(10.0, 40.0 - (delay - 120.0) * 0.3);
        }

        // Penalti BER / Packet loss
        if (ber > 1e-4) score -= 25.0;

        final isLag = delay > 60.0;
        telemetry = AppLiveTelemetry(
          metricPrimaryLabel: 'Ping Game',
          metricPrimaryValue: '${delay.toStringAsFixed(0)} ms',
          metricSecondaryLabel: 'Jitter',
          metricSecondaryValue: '${(delay * 0.08).toStringAsFixed(1)} ms',
          statusHighlight: isLag ? '🔴 LAG SPIKE RED ALERT' : '🟢 ESPORTS ULTRA SMOOTH',
          isAlertActive: isLag,
        );

        statusTitle = isLag ? 'Lag Spike Terdeteksi!' : 'Respon Server Sempurna';
        statusDescription = isLag
            ? 'Latensi ${delay.toStringAsFixed(0)}ms menyebabkan delay input skill & karakter patah-patah.'
            : 'Pergerakan karakter instan tanpa delay input, ideal untuk ranked match.';
        break;

      case 'whatsapp_call':
        // --- VOIP & VIDEO CALL (ITU-T G.107 MOS) ---
        // Estimasi Mean Opinion Score (1.0 - 5.0)
        double rFactor = 94.2 - (0.024 * delay) - (delay > 100 ? (delay - 100) * 0.11 : 0);
        rFactor -= (ber * 5000.0).clamp(0.0, 40.0);
        final mos = (1.0 + 0.035 * rFactor + rFactor * (100.0 - rFactor) * 7e-6).clamp(1.0, 4.5);

        score = ((mos - 1.0) / 3.5 * 100.0).clamp(15.0, 98.0);
        final isDropping = mos < 3.0;

        telemetry = AppLiveTelemetry(
          metricPrimaryLabel: 'Skor MOS',
          metricPrimaryValue: '${mos.toStringAsFixed(2)} / 5.0',
          metricSecondaryLabel: 'Latensi RTT',
          metricSecondaryValue: '${delay.toStringAsFixed(0)} ms',
          statusHighlight: isDropping ? '🔴 PANGGILAN TERANCAM PUTUS' : '🟢 SUARA HD JERNIH',
          isAlertActive: isDropping,
        );

        statusTitle = isDropping ? 'Kualitas Suara Rusak / Robotik' : 'Panggilan Suara & Video Stabil';
        statusDescription = isDropping
            ? 'MOS rendah (${mos.toStringAsFixed(2)}). Resiko panggilan video freeze atau terputus.'
            : 'Audio dua arah jernih bebas gema dan sinkronisasi video sempurna.';
        break;

      case 'youtube':
        // --- VIDEO STREAMING BUFFER QOE ---
        final neededBw = appProfile.sla.minDataRateMbps;
        final bufferHealthSec = (dataRate / math.max(1.0, neededBw) * 15.0).clamp(1.0, 60.0);

        if (dataRate >= 35.0) {
          score = 98.0;
        } else if (dataRate >= 15.0) {
          score = 80.0 + (dataRate - 15.0) * 0.9;
        } else if (dataRate >= 5.0) {
          score = 55.0 + (dataRate - 5.0) * 2.5;
        } else {
          score = math.max(15.0, dataRate * 10.0);
        }

        final isBuffering = dataRate < 5.0 || bufferHealthSec < 5.0;
        final resLabel = dataRate >= 35.0 ? '4K Ultra HD' : (dataRate >= 10.0 ? '1080p 60fps' : '480p SD');

        telemetry = AppLiveTelemetry(
          metricPrimaryLabel: 'Buffer Simpanan',
          metricPrimaryValue: '${bufferHealthSec.toStringAsFixed(0)} detik',
          metricSecondaryLabel: 'Resolusi Aktif',
          metricSecondaryValue: resLabel,
          statusHighlight: isBuffering ? '🔴 BUFFERING STUTTER' : '🟢 4K HDR PLAYBACK',
          isAlertActive: isBuffering,
        );

        statusTitle = isBuffering ? 'Video Mengalami Buffering' : 'Streaming Berjalan Mulus';
        statusDescription = isBuffering
            ? 'Bandwidth rendah (${dataRate.toStringAsFixed(1)} Mbps). Pemutaran terhenti untuk mengisi buffer.'
            : 'Video beresolusi tinggi mengalir lancar tanpa jeda buffering.';
        break;

      case 'cloud_download':
        // --- BULK DOWNLOAD & COST SAVINGS QOE ---
        final isWifi = activeSnapshot.technology == NetworkTechnology.wlan;
        score = ((dataRate / 100.0) * 60.0 + (isWifi ? 40.0 : 15.0)).clamp(20.0, 99.0);

        telemetry = AppLiveTelemetry(
          metricPrimaryLabel: 'Kecepatan Unduh',
          metricPrimaryValue: '${(dataRate / 8.0).toStringAsFixed(1)} MB/s',
          metricSecondaryLabel: 'Efisiensi Biaya',
          metricSecondaryValue: isWifi ? '100% Gratis (Wi-Fi)' : 'Menguras Kuota',
          statusHighlight: isWifi ? '💰 HEMAT KUOTA SELULER' : '⚠️ KUOTA SELULER TERPAKAI',
          isAlertActive: !isWifi && dataRate > 40.0,
        );

        statusTitle = isWifi ? 'Unduhan Hemat Kuota' : 'Menggunakan Kuota Seluler';
        statusDescription = isWifi
            ? 'File besar diunduh via Wi-Fi AP lokal tanpa memotong kuota paket data seluler.'
            : 'Kecepatan tinggi, namun beresiko menghabiskan kuota seluler dengan cepat.';
        break;

      default:
        // Standar Interactive / Social Media
        score = (60.0 + (dataRate / 20.0) * 20.0 - (delay / 300.0) * 20.0).clamp(25.0, 95.0);
        telemetry = AppLiveTelemetry(
          metricPrimaryLabel: 'Throughput',
          metricPrimaryValue: '${dataRate.toStringAsFixed(1)} Mbps',
          metricSecondaryLabel: 'Latensi',
          metricSecondaryValue: '${delay.toStringAsFixed(0)} ms',
          statusHighlight: '🟢 KONEKSI NORMAL',
          isAlertActive: false,
        );
        statusTitle = 'Performa Normal';
        statusDescription = 'Memuat konten web dan feed media sosial secara responsif.';
        break;
    }

    score = score.clamp(5.0, 100.0);
    final QoEHealthStatus status;
    if (score >= 85.0) {
      status = QoEHealthStatus.pristine;
    } else if (score >= 70.0) {
      status = QoEHealthStatus.good;
    } else if (score >= 50.0) {
      status = QoEHealthStatus.degraded;
    } else {
      status = QoEHealthStatus.critical;
    }

    // Proyeksi skor jika berpindah ke jaringan yang direkomendasikan
    double? projectedScore;
    String? benefitText;

    if (recommendedSnapshot != null &&
        recommendedSnapshot.available &&
        recommendedSnapshot.id != activeSnapshot.id) {
      final targetDelay = recommendedSnapshot.delayMs;
      final targetBw = recommendedSnapshot.dataRateMbps;

      if (appProfile.id == 'mobile_legends') {
        projectedScore = targetDelay < 30.0 ? 96.0 : (targetDelay < 60.0 ? 82.0 : 50.0);
        final diff = (delay - targetDelay).round();
        benefitText = diff > 0
            ? 'Pindah ke ${recommendedSnapshot.displayName}: Pangkas ping -$diff ms (${targetDelay.toStringAsFixed(0)}ms)'
            : 'Pindah ke ${recommendedSnapshot.displayName}: Latensi lebih stabil';
      } else if (appProfile.id == 'whatsapp_call') {
        projectedScore = targetDelay < 40.0 ? 95.0 : 80.0;
        benefitText = 'Pindah ke ${recommendedSnapshot.displayName}: Suara jernih & bebas putus';
      } else if (appProfile.id == 'youtube') {
        projectedScore = targetBw >= 35.0 ? 98.0 : 85.0;
        benefitText = 'Pindah ke ${recommendedSnapshot.displayName}: Bandwidth ${targetBw.toStringAsFixed(0)} Mbps (Tanpa Buffering)';
      } else if (appProfile.id == 'cloud_download') {
        final isTargetWifi = recommendedSnapshot.technology == NetworkTechnology.wlan;
        projectedScore = isTargetWifi ? 95.0 : 85.0;
        benefitText = isTargetWifi
            ? 'Pindah ke Wi-Fi: Hemat 100% kuota seluler'
            : 'Pindah ke ${recommendedSnapshot.displayName}: Unduhan lebih cepat';
      } else {
        projectedScore = 90.0;
        benefitText = 'Meningkatkan kesesuaian QoS aplikasi secara menyeluruh.';
      }
    }

    return QoEEvaluationResult(
      score: score,
      status: status,
      statusTitle: statusTitle,
      statusDescription: statusDescription,
      telemetry: telemetry,
      projectedScoreAfterHandover: projectedScore,
      handoverBenefitText: benefitText,
    );
  }
}
