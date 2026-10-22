import 'dart:math';

import '../handover/handover.dart';
import '../mobility/mobility.dart';
import 'simulation_models.dart';

/// Simulator lingkungan propagasi nirkabel sintetis (Synthetic Network Environment).
///
/// Mengimplementasikan [NetworkDataProvider] dengan:
/// - Log-distance path loss berdasarkan posisi pengguna terhadap base station.
/// - Penurunan throughput, delay, dan BER sesuai karakteristik fisik RF.
/// - Fluktuasi shadow fading Gaussian terkontrol.
/// - Reprodusibilitas penuh menggunakan random seed.
class SyntheticNetworkEnvironment implements NetworkDataProvider {
  final List<BaseStationNode> nodes;
  final List<ObstacleZone> obstacles;
  final Random _rng;
  final double pathLossExponent;
  final double shadowFadingStd;

  SyntheticNetworkEnvironment({
    List<BaseStationNode>? nodes,
    List<ObstacleZone>? obstacles,
    Random? rng,
    this.pathLossExponent = 3.0,
    this.shadowFadingStd = 1.0,
  })  : nodes = nodes ?? defaultSimulationBaseStations,
        obstacles = obstacles ?? defaultSimulationObstacles,
        _rng = rng ?? Random();

  /// Konstruktor dengan seed eksplisit untuk pengujian deterministik.
  factory SyntheticNetworkEnvironment.seeded(
    int seed, {
    List<BaseStationNode>? nodes,
    List<ObstacleZone>? obstacles,
    double pathLossExponent = 3.0,
    double shadowFadingStd = 1.0,
  }) {
    return SyntheticNetworkEnvironment(
      nodes: nodes,
      obstacles: obstacles,
      rng: Random(seed),
      pathLossExponent: pathLossExponent,
      shadowFadingStd: shadowFadingStd,
    );
  }

  /// Pembangkitan bilangan acak Gaussian dengan mean dan standard deviation.
  double _gaussianNoise(double mean, double stdDev) {
    if (stdDev <= 0) return mean;
    final u1 = _rng.nextDouble();
    final u2 = _rng.nextDouble();
    final safeU1 = u1 <= 0.0 ? 0.0001 : u1;
    final z = sqrt(-2.0 * log(safeU1)) * cos(2.0 * pi * u2);
    return mean + z * stdDev;
  }

  /// Interpolasi linear satu dimensi.
  static double _lerp(double lo, double hi, double t) {
    return lo + (hi - lo) * t.clamp(0.0, 1.0);
  }

  /// Interpolasi skala logaritmik (untuk Bit Error Rate).
  static double _lerpLog(double lo, double hi, double t) {
    if (lo <= 0 || hi <= 0) return lo;
    final logLo = log(lo) / ln10;
    final logHi = log(hi) / ln10;
    final val = pow(10.0, logLo + (logHi - logLo) * t.clamp(0.0, 1.0));
    return val.toDouble();
  }

  /// Override beban sel tertentu (misal untuk skenario kongesti buatan).
  final Map<String, double> forcedCellLoad = {};

  /// Mengatur beban sel manual untuk simulasi skenario khusus.
  void setCellLoad(String nodeId, double? load) {
    if (load == null) {
      forcedCellLoad.remove(nodeId);
    } else {
      forcedCellLoad[nodeId] = load.clamp(0.0, 1.0);
    }
  }

  /// Menghapus semua override beban sel manual.
  void clearForcedCellLoad() {
    forcedCellLoad.clear();
  }

  /// Menghitung faktor beban trafik dinamis (Cell Traffic Congestion) L(t) in [0.0, 1.0].
  /// Menggabungkan beban dasar stasioner, osilasi trafik pengguna jam sibuk (temporal drift wave),
  /// micro-burst alami, dan variasi Gaussian terkontrol tanpa white noise murni liar.
  double computeCellLoad(String nodeId, double elapsedSeconds) {
    if (forcedCellLoad.containsKey(nodeId)) {
      return forcedCellLoad[nodeId]!.clamp(0.0, 1.0);
    }

    double baseLoad;
    double wave;

    switch (nodeId) {
      case 'wifi':
        // Wi-Fi lokal kantor/kafe: fluktuasi dinamis akibat contention sharing banyak perangkat
        baseLoad = 0.28;
        wave = 0.16 * sin(elapsedSeconds * 2 * pi / 38.0) +
            0.08 * sin(elapsedSeconds * 2 * pi / 14.0);
        // Siklus burst periodik (misal unduhan file bersamaan setiap ~75 detik)
        final cycle = elapsedSeconds % 75.0;
        if (cycle >= 35.0 && cycle <= 55.0) {
          final burstProgress = (cycle - 35.0) / 20.0;
          wave += 0.35 * sin(burstProgress * pi);
        }
        break;

      case '5g_nr':
        // 5G mmWave/C-Band: kapasitas sangat lapang, beban relatif stabil dengan osilasi lambat
        baseLoad = 0.20;
        wave = 0.12 * sin((elapsedSeconds + 12.0) * 2 * pi / 55.0) +
            0.05 * sin(elapsedSeconds * 2 * pi / 22.0);
        break;

      case '4g_lte':
      default:
        // 4G Macro cell: trafik seluler publik yang aktif dan stabil
        baseLoad = 0.38;
        wave = 0.14 * sin((elapsedSeconds + 28.0) * 2 * pi / 48.0) +
            0.06 * sin(elapsedSeconds * 2 * pi / 19.0);
        break;
    }

    final noise = _gaussianNoise(0.0, 0.02);
    return (baseLoad + wave + noise).clamp(0.05, 0.95);
  }

  @override
  List<NetworkSnapshot> getSnapshots({
    required MobilityPoint userPosition,
    required double elapsedSeconds,
  }) {
    final snapshots = <NetworkSnapshot>[];

    for (final node in nodes) {
      final distance = max(1.0, node.distanceTo(userPosition));
      final inRange = distance <= node.coverageRadiusM;
      final loadFactor = computeCellLoad(node.id, elapsedSeconds);

      if (!inRange) {
        // Di luar jangkauan: sinyal terus melemah sesuai path loss terhadap jarak berlebih
        final extraLoss = 10.0 *
            pathLossExponent *
            (log(distance / node.coverageRadiusM) / ln10);
        final rawRss = node.rssMin -
            5.0 -
            extraLoss +
            _gaussianNoise(0.0, shadowFadingStd);
        final rssDbm = rawRss.clamp(-125.0, node.rssMin - 2.0);

        // Throughput menurun menuju batas minimum
        final dataRateMbps = (node.dataRateMin *
                (node.coverageRadiusM / distance))
            .clamp(0.1, node.dataRateMin);

        // Delay membengkak dengan jitter karena paket hilang / retransmisi
        final excessDistance = distance - node.coverageRadiusM;
        final extraDelay = (excessDistance / 10.0).clamp(0.0, 50.0);
        final delayMs = (node.delayMax * 1.5 +
                extraDelay +
                _gaussianNoise(0.0, 4.0))
            .clamp(node.delayMax, 250.0);

        snapshots.add(
          NetworkSnapshot(
            id: node.id,
            technology: node.technology,
            rssDbm: (rssDbm * 100).round() / 100.0,
            dataRateMbps: (dataRateMbps * 1000).round() / 1000.0,
            delayMs: (delayMs * 100).round() / 100.0,
            ber: node.berMax,
            available: false,
            parameterSource: ParameterSource.synthetic,
            loadFactor: (loadFactor * 100).round() / 100.0,
          ),
        );
        continue;
      }

      // Dalam jangkauan: hitung faktor kualitas jarak [0.0, 1.0]
      final ratio = distance / node.coverageRadiusM;
      final rawQuality = pow(1.0 - ratio, pathLossExponent / 3.0).toDouble();

      // Tambahkan noise propagasi kecil (+/- 2%)
      final noisyQuality =
          (rawQuality + _gaussianNoise(0.0, 0.02)).clamp(0.01, 0.99);

      // 1. Daya sinyal dasar (RSS)
      double rawRss = _lerp(node.rssMin, node.rssMax, noisyQuality) +
          _gaussianNoise(0.0, shadowFadingStd);

      // 2. Kecepatan data dasar (Throughput)
      final rateFactor = pow(noisyQuality, 1.5).toDouble();
      double dataRateMbps = _lerp(node.dataRateMin, node.dataRateMax, rateFactor);

      // 3. Delay dasar
      final delayFactor = pow(1.0 - noisyQuality, 1.2).toDouble();
      double delayMs = _lerp(node.delayMin, node.delayMax, delayFactor);

      // 4. Bit Error Rate dasar
      double ber = _lerpLog(node.berMax, node.berMin, noisyQuality);

      // Modulasi Throughput berdasarkan beban trafik sel dinamis (Channel capacity sharing)
      // Mengikuti kurva throughput efektif kanal CSMA/CA dan OFDMA saat utilitas meningkat
      final capacityRatio = pow(1.0 - (loadFactor * 0.96).clamp(0.0, 0.95), 1.8).clamp(0.02, 1.0);
      dataRateMbps = dataRateMbps * capacityRatio;

      // Modulasi Delay akibat antrian buffer (Bufferbloat / M/M/1 queueing delay)
      // Latensi membengkak tajam saat load mendekati saturasi (1 / (1 - load))
      final queueDelayMs = (pow(loadFactor, 2.0) / (1.05 - loadFactor)) *
          (node.technology == NetworkTechnology.wlan ? 7.0 : 5.0);
      delayMs = delayMs + queueDelayMs;

      // Modulasi BER akibat packet collisions pada kanal yang padat
      ber = ber * (1.0 + loadFactor * 2.5);

      // Deteksi apakah rintangan menghalangi sinyal antara base station dan pengguna (NLoS)
      final blockingObstacle = obstacles
          .where((o) => o.blocksLine(node.position, userPosition))
          .firstOrNull;

      double finalRssDbm;
      double finalDataRateMbps;
      double finalDelayMs;
      double finalBer;

      // Efek Fisika Rintangan (Obstacle / Non-Line-of-Sight Attenuation)
      if (blockingObstacle != null) {
        if (node.technology == NetworkTechnology.nr) {
          // 5G: Redaman Non-Line-of-Sight masif (gelombang milimeter / C-band terhalang gedung beton)
          // Penetrasi beton menyebabkan sinyal anjlok drastis (24-30 dB loss),
          // throughput ambruk ke 1.5 - 8 Mbps (tidak boleh di-clamp ke batas outdoor 50 Mbps),
          // delay membengkak (70 - 150 ms) akibat HARQ retransmissions, dan packet error melonjak.
          finalRssDbm = (rawRss - blockingObstacle.attenuation5gDb).clamp(-120.0, -96.0);
          finalDataRateMbps = (dataRateMbps * 0.05).clamp(1.5, 8.0);
          finalDelayMs = (delayMs + 70.0 + _gaussianNoise(8.0, 3.0)).clamp(65.0, 160.0);
          finalBer = (ber * 500.0).clamp(1e-4, 0.04);
        } else if (node.technology == NetworkTechnology.lte) {
          // 4G: Redaman penetrasi ringan (gelombang sub-2GHz mampu menembus material beton)
          // 4G tetap stabil dan menjadi pilihan jauh lebih unggul di dalam gedung beton
          finalRssDbm = (rawRss - blockingObstacle.attenuation4gDb).clamp(node.rssMin, node.rssMax);
          finalDataRateMbps = (dataRateMbps * 0.85).clamp(node.dataRateMin, node.dataRateMax);
          finalDelayMs = (delayMs + 4.0).clamp(node.delayMin, node.delayMax);
          finalBer = (ber * 2.0).clamp(node.berMin, node.berMax);
        } else {
          // Wi-Fi atau teknologi lain
          finalRssDbm = (rawRss - 18.0).clamp(node.rssMin, node.rssMax);
          finalDataRateMbps = (dataRateMbps * 0.25).clamp(node.dataRateMin, node.dataRateMax);
          finalDelayMs = (delayMs + 22.0).clamp(node.delayMin, node.delayMax);
          finalBer = (ber * 15.0).clamp(node.berMin, node.berMax);
        }
      } else {
        // Kondisi Line-of-Sight normal (Outdoor / tanpa rintangan)
        finalRssDbm = rawRss.clamp(node.rssMin, node.rssMax);
        finalDataRateMbps = dataRateMbps.clamp(node.dataRateMin, node.dataRateMax);
        finalDelayMs = delayMs.clamp(node.delayMin, node.delayMax);
        finalBer = ber.clamp(node.berMin, node.berMax);
      }

      snapshots.add(
        NetworkSnapshot(
          id: node.id,
          technology: node.technology,
          rssDbm: (finalRssDbm * 100).round() / 100.0,
          dataRateMbps: (finalDataRateMbps * 1000).round() / 1000.0,
          delayMs: (finalDelayMs * 100).round() / 100.0,
          ber: finalBer,
          available: true,
          parameterSource: ParameterSource.synthetic,
          loadFactor: (loadFactor * 100).round() / 100.0,
        ),
      );
    }

    return snapshots;
  }
}
