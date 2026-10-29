import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/handover/handover.dart';
import '../../core/realtime/realtime.dart';
import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/algorithm_vs_baseline_card.dart';
import '../../widgets/app_recommendation_card.dart';
import '../monitor/monitor_screen.dart';

/// Screen Realtime — Cockpit Telemetri Jaringan Fisik Riil & Vertical Handover (VHO)
///
/// Memiliki struktur layout yang konsisten & familiar dengan Monitor Simulasi:
/// 1. Kontrol Probe & Status Sensor Hardware
/// 2. Kartu Sensor Hardware Riil Wi-Fi & Seluler (Menggantikan Peta 2D Simulasi)
/// 3. Precaution Hardware & Status 5G (Deteksi Modem Infinix)
/// 4. Kartu Rekomendasi Aplikasi & Pemilihan SLA Spesifik
/// 5. Banner Keputusan Handover Live (Dengan tombol aksi Alihkan & Buka Panel OS)
/// 6. Komparasi Algoritma Fuzzy-TOPSIS vs RSS Baseline
/// 7. Daftar Kartu Jaringan Riil Aktif & Kandidat
class RealtimeScreen extends StatelessWidget {
  const RealtimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('realtime_scroll_key'),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Kontrol & Status Probe Realtime
            _RealtimeControlsCard(),
            SizedBox(height: 14),

            // 2. Kartu Sensor Hardware Riil Wi-Fi & Seluler (Pengganti Peta)
            _RealtimeHardwareSensorCard(),
            SizedBox(height: 14),

            // 3. Precaution Hardware & Status 5G
            _Realtime5GPrecautionCard(),
            SizedBox(height: 14),

            // 4. Kartu Rekomendasi Aplikasi & SLA Lengkap
            AppRecommendationCard(),
            SizedBox(height: 14),

            // 5. Banner Keputusan Handover Live (Highlight Aksi Cepat)
            _EnhancedLiveDecisionBanner(),
            SizedBox(height: 14),

            // 6. Perbandingan Algoritma Fuzzy-TOPSIS vs RSS Baseline
            AlgorithmVsBaselineCard(),
            SizedBox(height: 14),

            // 7. Daftar Kartu Jaringan Riil Aktif & Kandidat
            LiveNetworkCardsSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. CARD KONTROL & STATUS PROBE REALTIME
// ============================================================================
class _RealtimeControlsCard extends StatelessWidget {
  const _RealtimeControlsCard();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final live = controller.liveSnapshot;
    final isDark = context.isDark;
    final isAutoSwitch = controller.autoSwitchProcessBinding;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: live.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (live.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        live.isConnected ? 'Sensor Hardware Riil Aktif' : 'Mencoba Terhubung...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        live.activeTransport == 'cellular'
                            ? 'Rute Aktif HP: Seluler (${live.cellularOperator})'
                            : (live.activeTransport == 'wifi'
                                ? 'Rute Aktif HP: Wi-Fi (${live.networkName})'
                                : 'Rute: Tidak Ada Internet'),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.textSecondaryColor,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text(
                    'Uji Probe',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => controller.probeService.probeOnce(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mini Status Metrics Bar
            Row(
              children: [
                Expanded(
                  child: _MiniStatusTile(
                    icon: Icons.timer_outlined,
                    label: 'Ping RTT',
                    value: '${live.delayMs.toStringAsFixed(1)} ms',
                    isGood: live.delayMs < 60,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStatusTile(
                    icon: Icons.sync_problem_rounded,
                    label: 'Packet Loss',
                    value: '${(live.packetLossRate * 100).toStringAsFixed(0)}%',
                    isGood: live.packetLossRate < 0.05,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStatusTile(
                    icon: Icons.speed_rounded,
                    label: 'Mode Telemetri',
                    value: 'Live Device',
                    isGood: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: 10),

            // Baris Pengaturan Sensitivitas & Saklar Auto-Switch
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sensitivitas: ',
                      style: TextStyle(fontSize: 10.5, color: context.textSecondaryColor),
                    ),
                    DropdownButton<HandoverSensitivity>(
                      value: controller.sensitivity,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark ? const Color(0xFF1E2228) : Colors.white,
                      items: HandoverSensitivity.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.displayName.split(' ')[0],
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.setSensitivity(val);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Auto-Switch',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isAutoSwitch,
                      activeColor: AppTheme.accentBlue,
                      activeTrackColor: AppTheme.accentBlue.withOpacity(0.4),
                      onChanged: (val) => controller.setAutoSwitchProcessBinding(val),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isGood;

  const _MiniStatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2228) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: context.textSecondaryColor),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: context.textSecondaryColor,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isGood ? context.textPrimaryColor : Colors.redAccent,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. KARTU SENSOR HARDWARE RIIL WI-FI & SELULER (PENGGANTI PETA)
// ============================================================================
class _RealtimeHardwareSensorCard extends StatelessWidget {
  const _RealtimeHardwareSensorCard();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final live = controller.liveSnapshot;
    final isDark = context.isDark;
    final isMockRevoked = controller.isSimulatedLocationRevoked;

    // Kalkulasi latensi independen
    final effectiveWifi = LiveNetworkDataProvider.calculateEffectiveWifiThroughput(live.throughputMbps, live.rssDbm);
    final wifiDelay = live.rssDbm < -75.0 ? (live.delayMs + ((-75.0 - live.rssDbm) * 2.2)) : live.delayMs;
    final lteRss = live.isCellularConnected ? live.cellularRssiDbm : -72.0;
    final lteSignalQuality = ((lteRss - (-120.0)) / 65.0).clamp(0.05, 1.0);
    final lteDelay = (22.0 + (1.0 - lteSignalQuality) * 26.0).clamp(18.0, 95.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.sensors_rounded, size: 16, color: AppTheme.accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Telemetri Sensor Perangkat Fisik',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Baris Izin Hardware
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2228) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Izin Hardware: ',
                        style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                      ),
                      _PermissionBadge(
                        label: isMockRevoked ? 'Lokasi: Dicabut (Mock)' : (live.hasLocationPermission ? 'Lokasi: Aktif' : 'Lokasi: Belum Ada'),
                        isGranted: live.hasLocationPermission && !isMockRevoked,
                      ),
                      _PermissionBadge(
                        label: live.hasPhonePermission ? 'Telepon: Aktif' : 'Telepon: Belum Ada',
                        isGranted: live.hasPhonePermission,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.settings_outlined, size: 12),
                          label: const Text('Kelola Izin Android', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: context.borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => controller.openAppSettings(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            isMockRevoked ? Icons.restore_rounded : Icons.block_rounded,
                            size: 12,
                            color: isMockRevoked ? const Color(0xFF10B981) : AppTheme.errorRed,
                          ),
                          label: Text(
                            isMockRevoked ? 'Pulihkan Izin' : 'Cabut Izin (Test)',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isMockRevoked ? const Color(0xFF10B981) : AppTheme.errorRed,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: isMockRevoked ? const Color(0xFF10B981) : AppTheme.errorRed.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => controller.toggleSimulatedLocationRevocation(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 1. Seksi Wi-Fi
            Row(
              children: [
                const Icon(Icons.wifi_rounded, size: 18, color: AppTheme.accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wi-Fi: ${live.networkName}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                    softWrap: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: live.isConnected ? AppTheme.successGreen.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    live.isConnected ? 'Terhubung' : 'Terputus',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: live.isConnected ? AppTheme.successGreen : Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SensorMetricBox(
                    label: 'Sinyal Wi-Fi',
                    value: '${live.rssDbm.toStringAsFixed(0)} dBm',
                    icon: Icons.wifi_find_rounded,
                    isGood: live.rssDbm > -72,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SensorMetricBox(
                    label: 'Laju Efektif',
                    value: '${effectiveWifi.toStringAsFixed(1)} Mbps',
                    icon: Icons.compress_rounded,
                    isGood: live.rssDbm > -75,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SensorMetricBox(
                    label: 'Latensi Ping',
                    value: '${wifiDelay.toStringAsFixed(0)} ms',
                    icon: Icons.timer_outlined,
                    isGood: wifiDelay < 60,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: 10),

            // 2. Seksi Data Seluler
            Row(
              children: [
                const Icon(Icons.cell_tower_rounded, size: 18, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seluler: ${live.cellularOperator} (${live.cellularType})',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                    softWrap: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: live.isCellularConnected ? AppTheme.successGreen.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    live.isCellularConnected ? 'Standby/Aktif' : 'Tidak Aktif',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: live.isCellularConnected ? AppTheme.successGreen : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SensorMetricBox(
                    label: 'Sinyal Antena',
                    value: '${live.cellularRssiDbm.toStringAsFixed(0)} dBm',
                    icon: Icons.cell_tower_rounded,
                    isGood: live.cellularRssiDbm > -85,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SensorMetricBox(
                    label: 'Throughput',
                    value: '${live.cellularThroughputMbps.toStringAsFixed(1)} Mbps',
                    icon: Icons.speed_rounded,
                    isGood: live.cellularThroughputMbps > 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SensorMetricBox(
                    label: 'Latensi LTE',
                    value: '${lteDelay.toStringAsFixed(0)} ms',
                    icon: Icons.network_ping_rounded,
                    isGood: lteDelay < 50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  final String label;
  final bool isGranted;

  const _PermissionBadge({required this.label, required this.isGranted});

  @override
  Widget build(BuildContext context) {
    final color = isGranted ? const Color(0xFF10B981) : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _SensorMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isGood;

  const _SensorMetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2228) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: context.textSecondaryColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 9.5, color: context.textSecondaryColor),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isGood ? context.textPrimaryColor : Colors.redAccent,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. PRECAUTION HARDWARE & STATUS 5G (INFINIX SUPPORT)
// ============================================================================
class _Realtime5GPrecautionCard extends StatelessWidget {
  const _Realtime5GPrecautionCard();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final live = controller.liveSnapshot;
    final isDark = context.isDark;
    final is5g = live.is5gHardwareSupported || live.is5gAvailable;
    final accentColor = is5g ? const Color(0xFF10B981) : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: is5g
            ? (isDark ? const Color(0xFF064E3B).withOpacity(0.2) : const Color(0xFFECFDF5))
            : (isDark ? const Color(0xFF451A03).withOpacity(0.2) : const Color(0xFFFFFBEB)),
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              is5g ? Icons.five_g_rounded : Icons.cell_wifi_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  is5g
                      ? 'Modem 5G NR Terdeteksi & Didukung'
                      : 'Hardware 5G NR Tidak Didukung (Mode 4G LTE Aktif)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Text(
                  is5g
                      ? 'Perangkat & SIM mendukung pita frekuensi New Radio'
                      : 'Perangkat Infinix beroperasi optimal pada arsitektur 4G LTE & Wi-Fi',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. BANNER KEPUTUSAN HANDOVER LIVE ENHANCED (Dengan Tombol Aksi Langsung)
// ============================================================================
class _EnhancedLiveDecisionBanner extends StatelessWidget {
  const _EnhancedLiveDecisionBanner();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final isRecommended = controller.isHandoverRecommended;
    final targetId = controller.recommendedTargetId;
    final isDark = context.isDark;
    final isAutoSwitch = controller.autoSwitchProcessBinding;
    final isBoundTarget = targetId != null &&
        ((targetId.contains('wifi') && controller.processBindingStatus == 'wifi') ||
         (!targetId.contains('wifi') && controller.processBindingStatus == 'cellular'));

    if (!isRecommended) {
      return const LiveDecisionBanner();
    }

    final targetLabel = formatNetworkLabel(targetId);
    final targetSnapshot = controller.currentSnapshots.where((s) => s.id == targetId).firstOrNull;
    final targetSpeed = targetSnapshot != null ? '${targetSnapshot.dataRateMbps.toStringAsFixed(0)} Mbps' : 'Lebih Cepat';
    final profile = controller.activeAppProfile;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF331B10) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: const Color(0xFFEA580C), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_calls_rounded, color: Color(0xFFEA580C), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saran Handover: Pindah ke $targetLabel',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF9A3412),
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Wi-Fi saat ini berisiko melanggar target SLA ${profile.name} (Min ${profile.sla.minDataRateMbps} Mbps). Jaringan $targetLabel terdeteksi memiliki performa unggul ($targetSpeed).',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white70 : const Color(0xFFC2410C),
                        height: 1.25,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBoundTarget ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    elevation: 0,
                  ),
                  icon: Icon(isBoundTarget ? Icons.check_rounded : Icons.bolt_rounded, size: 16),
                  label: Text(
                    isBoundTarget
                        ? 'Soket Aplikasi Sudah di $targetLabel'
                        : 'Alihkan Data Aplikasi ke $targetLabel',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    softWrap: true,
                  ),
                  onPressed: isBoundTarget
                      ? null
                      : () => controller.executeManualProcessSwitch(targetId!),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF9A3412),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  side: const BorderSide(color: Color(0xFFEA580C), width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
                child: const Text('Buka Panel OS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => controller.openInternetPanel(),
              ),
            ],
          ),

          if (isAutoSwitch) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.auto_mode_rounded, size: 13, color: Color(0xFF10B981)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Fitur Auto-Switch Aktif: Aplikasi otomatis mengikat proses ke $targetLabel',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
