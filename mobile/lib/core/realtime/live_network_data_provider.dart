import 'dart:math' as math;
import '../handover/models.dart';
import '../mobility/mobility.dart';
import '../simulation/simulation_models.dart';
import 'network_probe_service.dart';

/// Implementasi NetworkDataProvider berbasis pengukuran hardware riil.
///
/// Menyajikan metrik nyata dari kartu jaringan fisik pengguna (Wi-Fi/Ethernet)
/// sekaligus mendeteksi sinyal jaringan seluler riil (4G LTE / 5G NR) pada Android
/// atau menyediakan kandidat pembanding untuk evaluasi Vertical Handover (VHO).
class LiveNetworkDataProvider implements NetworkDataProvider {
  final NetworkProbeService probeService;

  LiveNetworkDataProvider({
    NetworkProbeService? probeService,
  }) : probeService = probeService ?? NetworkProbeService();

  /// Menghitung throughput efektif realistis dari link Wi-Fi berbasis degradasi sinyal (RSSI).
  ///
  /// Menghindari inflasi raw PHY speed (misal 72 Mbps atau 144 Mbps yang dilaporkan
  /// oleh Android WifiManager) pada kondisi sinyal lemah (2 bar / < -75 dBm)
  /// akibat MCS index drop dan retransmisi paket tinggi.
  static double calculateEffectiveWifiThroughput(double rawPhySpeedMbps, double rssDbm) {
    if (rawPhySpeedMbps <= 0) return 0.0;
    if (rssDbm >= -65.0) {
      // 4-5 Bar: Kondisi prima, efisiensi transport normal ~70%
      return (rawPhySpeedMbps * 0.70).clamp(5.0, 300.0);
    } else if (rssDbm >= -75.0) {
      // 3 Bar: Sedang, efisiensi ~45%
      return (rawPhySpeedMbps * 0.45).clamp(3.0, 150.0);
    } else if (rssDbm >= -82.0) {
      // 2 Bar (-75 s/d -82 dBm): MCS drop drastis + frame retries tinggi
      // Effective throughput riil anjlok ke ~2 - 6 Mbps
      return (rawPhySpeedMbps * 0.08).clamp(1.5, 6.5);
    } else {
      // 1 Bar (< -82 dBm): Sinyal kritis ambang putus
      return (rawPhySpeedMbps * 0.02).clamp(0.2, 1.8);
    }
  }

  @override
  List<NetworkSnapshot> getSnapshots({
    required MobilityPoint userPosition,
    required double elapsedSeconds,
  }) {
    final live = probeService.latestSnapshot;

    // 1. Snapshot Jaringan Wi-Fi Riil
    final realWifiBer = math.max(1e-7, live.packetLossRate * 0.05);
    final effectiveWifiRate = calculateEffectiveWifiThroughput(
      live.throughputMbps,
      live.rssDbm,
    );
    // Latensi Wi-Fi riil: mengalami degradasi tajam saat sinyal rendah akibat MAC contention
    final wifiDelayPenalty = live.rssDbm < -75.0 ? ((-75.0 - live.rssDbm) * 2.2) : 0.0;
    final realWifiDelay = (live.delayMs + wifiDelayPenalty).clamp(8.0, 500.0);

    final wifiSnapshot = NetworkSnapshot(
      id: 'wifi',
      technology: NetworkTechnology.wlan,
      rssDbm: live.rssDbm,
      dataRateMbps: effectiveWifiRate,
      delayMs: realWifiDelay,
      ber: realWifiBer,
      available: live.isConnected,
    );

    // 2. Snapshot Jaringan Seluler (4G LTE)
    final isCellularReal = live.isCellularConnected;
    final isNr = live.is5gAvailable || live.cellularTech == 'nr';

    final lteRss = isCellularReal ? live.cellularRssiDbm : -72.0;
    final lteRate =
        isCellularReal ? live.cellularThroughputMbps : 35.0;

    // Latensi 4G LTE Independen: Model Standar 3GPP LTE Rel-15
    // Menghitung latensi interface radio LTE secara independen berbasis kualitas RSRP
    final lteSignalQuality = ((lteRss - (-120.0)) / 65.0).clamp(0.05, 1.0);
    final lteIndependentDelay = (22.0 + (1.0 - lteSignalQuality) * 26.0).clamp(18.0, 95.0);

    final lteSnapshot = NetworkSnapshot(
      id: '4g_lte',
      technology: NetworkTechnology.lte,
      rssDbm: lteRss,
      dataRateMbps: lteRate,
      delayMs: lteIndependentDelay,
      ber: 1e-6,
      available: isCellularReal,
    );

    // 3. Snapshot Jaringan Seluler (5G NR)
    // Hanya tersedia jika modem/sinyal HP mendeteksi jaringan 5G aktif
    final nrRss = isNr ? live.cellularRssiDbm : -120.0;
    final nrRate = isNr ? live.cellularThroughputMbps : 0.0;
    final nrDelay = isNr ? 14.0 : 999.0;

    final nrSnapshot = NetworkSnapshot(
      id: '5g_nr',
      technology: NetworkTechnology.nr,
      rssDbm: nrRss,
      dataRateMbps: nrRate,
      delayMs: nrDelay,
      ber: 1e-7,
      available: isNr,
    );

    return [wifiSnapshot, lteSnapshot, nrSnapshot];
  }
}
