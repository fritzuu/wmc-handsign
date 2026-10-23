import 'dart:math' as math;
import '../handover/models.dart';
import '../mobility/mobility.dart';
import '../simulation/simulation_models.dart';
import 'network_probe_service.dart';

/// Implementasi NetworkDataProvider berbasis pengukuran hardware riil.
///
/// Menyajikan metrik nyata dari kartu jaringan fisik pengguna (Wi-Fi/Ethernet)
/// sekaligus menyediakan kandidat jaringan seluler (4G LTE / 5G NR) untuk
/// memungkinkan algoritma evaluasi Vertical Handover (VHO) bekerja secara komparatif.
class LiveNetworkDataProvider implements NetworkDataProvider {
  final NetworkProbeService probeService;

  LiveNetworkDataProvider({
    NetworkProbeService? probeService,
  }) : probeService = probeService ?? NetworkProbeService();

  @override
  List<NetworkSnapshot> getSnapshots({
    required MobilityPoint userPosition,
    required double elapsedSeconds,
  }) {
    final live = probeService.latestSnapshot;

    // 1. Snapshot Jaringan Riil (Berdasarkan pengukuran sensor hardware pengguna)
    final realWifiBer = math.max(1e-7, live.packetLossRate * 0.05);

    final wifiSnapshot = NetworkSnapshot(
      id: 'wifi',
      technology: NetworkTechnology.wlan,
      rssDbm: live.rssDbm,
      dataRateMbps: live.throughputMbps,
      delayMs: live.delayMs,
      ber: realWifiBer,
      available: live.isConnected,
    );

    // 2. Kandidat Seluler Pembanding (4G LTE Macro)
    // Mensimulasikan ketersediaan sinyal seluler operator di lokasi fisik pengguna
    final lteSnapshot = NetworkSnapshot(
      id: '4g_lte',
      technology: NetworkTechnology.lte,
      rssDbm: -72.0,
      dataRateMbps: 35.0,
      delayMs: 38.0,
      ber: 1e-6,
      available: true,
    );

    // 3. Kandidat Seluler Pembanding (5G NR Standalone)
    final nrSnapshot = NetworkSnapshot(
      id: '5g_nr',
      technology: NetworkTechnology.nr,
      rssDbm: -68.0,
      dataRateMbps: 220.0,
      delayMs: 12.0,
      ber: 1e-7,
      available: true,
    );

    return [wifiSnapshot, lteSnapshot, nrSnapshot];
  }
}
