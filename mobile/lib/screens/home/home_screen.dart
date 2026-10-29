import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_recommendation_card.dart';

/// Screen 2 — Home Dashboard: Executive Command Center
///
/// Menyajikan overview komprehensif sistem Vertical Handover (VHO):
/// - Header status sistem & engine
/// - Panel Pemilihan Sumber Data (Dropdown Simulasi HetNet vs Realtime Hardware)
/// - 4-Grid KPI Telemetri Dinamis Adaptif
/// - Dual Flagship Showcase (Simulasi Kampus 2D vs Telemetri Hardware HP)
/// - Rekomendasi SLA Aplikasi Aktif
/// - Menu Cepat 4-Kartu Simetris Bebas Teks Terpotong
/// - Stepper Alur Algoritma 5-Tahap Ndegwa et al. (2023)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('home_scroll_key'),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Command Center
            _HomeHeaderSection(),
            SizedBox(height: 12),

            // 2. Panel Pemilihan Sumber Data (Simulasi vs Realtime)
            _DashboardSourceSelector(),
            SizedBox(height: 14),

            // 3. 4-Grid KPI Telemetry HUD
            _KpiTelemetryHud(),
            SizedBox(height: 16),

            // 4. Dual Flagship Cards (Simulasi Kampus vs Realtime Hardware)
            _DualFlagshipShowcase(),
            SizedBox(height: 16),

            // 5. Rekomendasi Aplikasi & SLA
            AppRecommendationCard(compact: true),
            SizedBox(height: 16),

            // 6. Menu Utama Alat Cepat (Symmetric 4-Card Grid)
            _MainMenuGridSection(),
            SizedBox(height: 16),

            // 7. Alur Algoritma Simulator (Pipeline 5 Tahap)
            _SimulatorWorkflowSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Header Command Center dengan Status Engine
class _HomeHeaderSection extends StatelessWidget {
  const _HomeHeaderSection();

  @override
  Widget build(BuildContext context) {
    final isRunning =
        context.select<SimulationController, bool>((c) => c.isRunning);
    final stepIndex =
        context.select<SimulationController, int>((c) => c.stepIndex);
    final isLive =
        context.select<SimulationController, bool>((c) => c.isLiveMode);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBlack : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WMC Command Center',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Smart Vertical Handover · Ndegwa et al. (2023)',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.textSecondaryColor,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isLive
                      ? const Color(0xFF10B981)
                      : (isRunning
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFF59E0B)))
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (isLive
                        ? const Color(0xFF10B981)
                        : (isRunning
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFF59E0B)))
                    .withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFF10B981)
                        : (isRunning
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFF59E0B)),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isLive
                      ? 'REALTIME HP'
                      : (isRunning ? 'STEP $stepIndex' : 'STANDBY'),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isLive
                        ? const Color(0xFF10B981)
                        : (isRunning
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel Dropdown & Segmented Pemilihan Sumber Data (Simulasi vs Realtime Hardware)
class _DashboardSourceSelector extends StatelessWidget {
  const _DashboardSourceSelector();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final mode = controller.dataSourceMode;
    final isLive = mode == SimulationDataSourceMode.liveHardwareProbe;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2228) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(
          color: isLive
              ? const Color(0xFF10B981).withOpacity(0.4)
              : const Color(0xFF6366F1).withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 15,
                color: isLive ? const Color(0xFF10B981) : const Color(0xFF6366F1),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sumber Data Telemetri Dashboard:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardBlack : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SimulationDataSourceMode>(
                value: mode,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E2228) : Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                items: [
                  DropdownMenuItem(
                    value: SimulationDataSourceMode.simulationHetNet,
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined,
                            size: 16, color: Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Simulasi Kampus (RWP HetNet)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: !isLive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: SimulationDataSourceMode.liveHardwareProbe,
                    child: Row(
                      children: [
                        const Icon(Icons.sensors_rounded,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Realtime Sensor HP (Infinix Note 50 Pro)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isLive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (newMode) {
                  if (newMode != null) {
                    controller.setDataSourceMode(newMode);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isLive
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 13,
                color: isLive ? const Color(0xFF10B981) : const Color(0xFF6366F1),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isLive
                      ? 'Dashboard membaca antena fisik Wi-Fi & Seluler HP Anda secara langsung.'
                      : 'Dashboard menampilkan skenario mobilitas HetNet 1000m × 1000m.',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondaryColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 4-Grid KPI Telemetry HUD (2x2 Grid Bebas Teks Terpotong)
class _KpiTelemetryHud extends StatelessWidget {
  const _KpiTelemetryHud();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final isLive = controller.isLiveMode;
    final live = controller.liveSnapshot;

    final activeSnap = controller.activeNetworkSnapshot;
    final qoe = controller.currentQoE;
    final vhoCount = controller.smartVhoHandoverCount;
    final preventedPingPong = controller.preventedPingPongCount;
    final savedMb = controller.cellularDataSavedMb;

    // Nilai KPI yang dinamis menyesuaikan mode sumber data
    final String activeName;
    final String activeSub;
    if (isLive) {
      if (live.activeTransport == 'cellular') {
        activeName = '${live.cellularOperator} (${live.cellularType})';
        activeSub =
            '${live.cellularRssiDbm.toStringAsFixed(0)} dBm · ${live.cellularThroughputMbps.toStringAsFixed(1)} Mbps';
      } else {
        activeName = live.networkName;
        activeSub =
            '${live.rssDbm.toStringAsFixed(0)} dBm · ${live.throughputMbps.toStringAsFixed(0)} Mbps';
      }
    } else {
      activeName = activeSnap?.displayName ?? 'Mencari...';
      activeSub = activeSnap != null
          ? '${activeSnap.rssDbm.toStringAsFixed(0)} dBm · ${activeSnap.dataRateMbps.toStringAsFixed(0)} Mbps'
          : 'Menghubungkan';
    }

    final String qoeScoreText = isLive
        ? (live.isConnected ? '${(100 - live.packetLossRate * 100).clamp(50, 100).toStringAsFixed(0)}%' : '0%')
        : '${(qoe?.score ?? 85).toStringAsFixed(0)}%';
    final String qoeSubText = isLive
        ? (live.delayMs < 50 ? 'Prima (Sub-50ms)' : 'Latency: ${live.delayMs.toStringAsFixed(0)}ms')
        : '${qoe?.statusTitle.split(' ').first ?? 'Prima'} Status';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Kiri
        Expanded(
          child: Column(
            children: [
              _KpiTile(
                icon: Icons.wifi_tethering_rounded,
                title: isLive ? 'Jaringan HP Aktif' : 'Jaringan Aktif',
                value: activeName,
                subtext: activeSub,
                accentColor: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 10),
              _KpiTile(
                icon: Icons.compare_arrows_rounded,
                title: 'Handover / VHO',
                value: '$vhoCount Kali',
                subtext: '$preventedPingPong Ping-Pong Dicegah',
                accentColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Kolom Kanan
        Expanded(
          child: Column(
            children: [
              _KpiTile(
                icon: Icons.speed_rounded,
                title: 'Skor QoE Aplikasi',
                value: qoeScoreText,
                subtext: qoeSubText,
                accentColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),
              _KpiTile(
                icon: Icons.data_saver_on_rounded,
                title: 'Hemat Kuota Data',
                value: '${savedMb.toStringAsFixed(1)} MB',
                subtext: 'Offload ke Wi-Fi',
                accentColor: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtext;
  final Color accentColor;

  const _KpiTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtext,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBlack : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
              height: 1.15,
            ),
            maxLines: 2,
            softWrap: true,
          ),
          const SizedBox(height: 3),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9.5,
              color: context.textTertiaryColor,
              height: 1.15,
            ),
            maxLines: 2,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

/// Dual Flagship Showcase Cards (Simulasi Kampus vs Realtime Hardware)
class _DualFlagshipShowcase extends StatelessWidget {
  const _DualFlagshipShowcase();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_customize_rounded,
                size: 15, color: context.textPrimaryColor),
            const SizedBox(width: 6),
            Text(
              'Modul Utama Sistem',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu 1: Monitor Simulasi Kampus
            Expanded(
              child: _FlagshipModuleCard(
                tag: 'SIMULATOR HETNET',
                title: 'Simulasi Kampus 2D',
                desc: 'Peta mobilitas RWP, radius sinyal, & kontrol playback.',
                icon: Icons.map_outlined,
                actionLabel: 'Buka Simulasi',
                accentColor: const Color(0xFF6366F1),
                isDark: isDark,
                onTap: () => context.go('/monitor'),
              ),
            ),
            const SizedBox(width: 10),
            // Kartu 2: Telemetri Hardware Realtime
            Expanded(
              child: _FlagshipModuleCard(
                tag: 'HARDWARE SENSOR',
                title: 'Realtime Hardware',
                desc: 'Antena Wi-Fi & Seluler HP riil, probe soket, & status 5G.',
                icon: Icons.sensors_rounded,
                actionLabel: 'Buka Realtime',
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => context.go('/realtime'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlagshipModuleCard extends StatelessWidget {
  final String tag;
  final String title;
  final String desc;
  final IconData icon;
  final String actionLabel;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _FlagshipModuleCard({
    required this.tag,
    required this.title,
    required this.desc,
    required this.icon,
    required this.actionLabel,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 9.5,
                  color: context.textSecondaryColor,
                  height: 1.25,
                ),
                maxLines: 3,
                softWrap: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 11, color: accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu Utama Grid Simetris Bebas Teks Terpotong (childAspectRatio: 1.25)
class _MainMenuGridSection extends StatelessWidget {
  const _MainMenuGridSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.widgets_outlined,
                size: 15, color: context.textPrimaryColor),
            const SizedBox(width: 6),
            Text(
              'Menu Utama',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25, // Memberikan tinggi vertikal cukup agar subtitle 2 baris tidak terpotong
          children: [
            _MenuActionCard(
              title: 'Hasil Evaluasi',
              subtitle: 'Metrik handover & performa komparasi',
              icon: Icons.analytics_outlined,
              onTap: () => context.go('/results'),
            ),
            _MenuActionCard(
              title: 'Log Keputusan',
              subtitle: 'Audit trail TOPSIS & QoS lengkap',
              icon: Icons.list_alt_rounded,
              onTap: () => context.push('/logs'),
            ),
            _MenuActionCard(
              title: 'Konfigurasi',
              subtitle: 'Ambang Fuzzy & bobot kriteria AHP',
              icon: Icons.tune_rounded,
              onTap: () => context.go('/settings'),
            ),
            _MenuActionCard(
              title: 'Kontrol Skenario',
              subtitle: 'Lompat waktu, jeda & reset skenario',
              icon: Icons.fast_forward_rounded,
              onTap: () => _showScenarioControls(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showScenarioControls(BuildContext context) {
    final controller = context.read<SimulationController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isRunning = controller.isRunning;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kontrol Skenario Simulasi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Lompat waktu mobilitas atau kelola status pemutaran:',
                style: TextStyle(
                    fontSize: 11.5, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sec in [10, 50, 100, 250, 500])
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        side: BorderSide(color: context.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.fastForward(sec);
                      },
                      child: Text(
                        '+$sec Detik',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: context.borderColor),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isRunning ? Colors.orange : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                          isRunning ? Icons.pause : Icons.play_arrow,
                          size: 16),
                      label: Text(
                        isRunning ? 'Jeda Simulasi' : 'Mulai Simulasi',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (isRunning) {
                          controller.pause();
                        } else {
                          controller.start();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(color: AppTheme.errorRed.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text(
                      'Reset',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.reset();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _MenuActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: context.textPrimaryColor, size: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.textSecondaryColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alur Simulator 5 Tahap (Pipeline Vertikal Modern Bebas Cutoff)
class _SimulatorWorkflowSection extends StatelessWidget {
  const _SimulatorWorkflowSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: context.textPrimaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alur Simulator Vertical Handover',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF1F1F1F)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    '5 TAHAP',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pipeline pengambilan keputusan algoritma Ndegwa et al. (2023):',
              style: TextStyle(fontSize: 10.5, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            const _PipelineStepItem(
              stepNumber: '01',
              title: 'Generator Mobilitas & RF',
              subtitle: 'Simulasi mobilitas RWP & Path Loss kanal 4G/5G/Wi-Fi',
              icon: Icons.cell_tower,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '02',
              title: 'Normalisasi QoS Factor',
              subtitle: 'Evaluasi Throughput, Latensi/Delay, dan Packet Loss/BER',
              icon: Icons.calculate_outlined,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '03',
              title: 'Fuzzy Mamdani (Inisiasi)',
              subtitle: 'Evaluasi Handover Factor (HF) terhadap ambang dinamis',
              icon: Icons.psychology_outlined,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '04',
              title: 'TOPSIS (Seleksi Target)',
              subtitle: 'Perangkingan kandidat terbaik dengan matriks bobot AHP',
              icon: Icons.sort_outlined,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '05',
              title: 'Stabilizer (Anti Ping-Pong)',
              subtitle: 'Dwell time 3.0s & hysteresis gain minimum >= 0.05',
              icon: Icons.shield_outlined,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineStepItem extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLast;

  const _PipelineStepItem({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF262626)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: context.borderColor,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSecondaryColor,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, size: 15, color: context.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
