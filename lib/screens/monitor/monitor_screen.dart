import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';

/// Screen 6 — Live Monitor Cockpit Shell (PRD v1.0/v2.0)
///
/// Menampilkan:
/// - Status ringkas simulasi & kontrol play/pause/step
/// - Indikator mobilitas pengguna
/// - Live Network Cards (4G, 5G, Wi-Fi) & Live Decision Banner (Step 3 target)
class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('monitor_scroll_key'),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MonitorPlaybackBar(),
            SizedBox(height: 16),
            _MobilityPositionQuickCard(),
            SizedBox(height: 16),
            _LiveDecisionBannerPlaceholder(),
            SizedBox(height: 16),
            _LiveNetworkCardsSectionPlaceholder(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Bar Kontrol Playback & Kemajuan Simulasi
class _MonitorPlaybackBar extends StatelessWidget {
  const _MonitorPlaybackBar();

  @override
  Widget build(BuildContext context) {
    final stepIndex = context.select<SimulationController, int>((c) => c.stepIndex);
    final elapsedSeconds = context.select<SimulationController, double>((c) => c.elapsedSeconds);
    final isRunning = context.select<SimulationController, bool>((c) => c.isRunning);

    final currentSpeed = context.select<SimulationController, int>((c) => c.playbackSpeed);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? AppTheme.successGreen.withValues(alpha: 0.12)
                        : AppTheme.warningOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRunning ? Icons.play_circle : Icons.pause_circle,
                    color: isRunning ? AppTheme.successGreen : AppTheme.warningOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Langkah $stepIndex · Waktu: ${elapsedSeconds.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRunning
                            ? 'Simulasi berjalan live (${currentSpeed}x speed)'
                            : 'Simulasi terjeda',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 22),
                      tooltip: 'Step (+1s)',
                      color: AppTheme.primaryBlue,
                      onPressed: () => context.read<SimulationController>().step(1.0),
                    ),
                    IconButton(
                      icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 22),
                      tooltip: isRunning ? 'Jeda' : 'Jalankan',
                      color: isRunning ? AppTheme.warningOrange : AppTheme.successGreen,
                      onPressed: () {
                        final c = context.read<SimulationController>();
                        if (c.isRunning) {
                          c.pause();
                        } else {
                          c.start();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.restart_alt, size: 20),
                      tooltip: 'Reset',
                      color: AppTheme.textTertiary,
                      onPressed: () => context.read<SimulationController>().reset(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Playback speed chips
                  const Text(
                    'Speed: ',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  ...[1, 2, 5, 10, 20].map((s) {
                    final isSelected = currentSpeed == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: InkWell(
                        onTap: () => context.read<SimulationController>().setPlaybackSpeed(s),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.dividerColor,
                            ),
                          ),
                          child: Text(
                            '${s}x',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 16, color: AppTheme.dividerColor),
                  const SizedBox(width: 12),
                  // Fast Forward Shortcuts
                  const Text(
                    'Lompat: ',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  ...[10, 50, 100, 500].map((count) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ActionChip(
                        label: Text(
                          '+${count}s',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                        backgroundColor: AppTheme.lightBlueBg,
                        side: const BorderSide(color: AppTheme.primaryBlue, width: 0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.read<SimulationController>().fastForward(count),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu Cepat Posisi & Kecepatan Pengguna
class _MobilityPositionQuickCard extends StatelessWidget {
  const _MobilityPositionQuickCard();

  @override
  Widget build(BuildContext context) {
    final pos = context.select<SimulationController, String>(
      (c) => '(${c.userPosition.x.toStringAsFixed(1)}, ${c.userPosition.y.toStringAsFixed(1)}) m',
    );
    final speed = context.select<SimulationController, String>(
      (c) => '${c.velocityMps.toStringAsFixed(2)} m/s',
    );
    final isMoving = context.select<SimulationController, bool>(
      (c) => c.mobilityState.isMoving,
    );

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_walk, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Posisi & Mobilitas Pengguna',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Koordinat (X, Y)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(pos, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kecepatan Efektif', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(speed, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMoving ? AppTheme.lightGreenBg : AppTheme.lightOrangeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMoving ? 'MOVING' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMoving ? AppTheme.successGreen : AppTheme.warningOrange,
                    ),
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

/// Placeholder Banner Keputusan Handover Live (Akan diisi detail di Step 3)
class _LiveDecisionBannerPlaceholder extends StatelessWidget {
  const _LiveDecisionBannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final activeId = context.select<SimulationController, String>((c) => c.activeNetworkId);
    final isUnavailable = context.select<SimulationController, bool>((c) => c.isActiveNetworkUnavailable);
    final isRecommended = context.select<SimulationController, bool>((c) => c.isHandoverRecommended);
    final targetId = context.select<SimulationController, String?>((c) => c.recommendedTargetId);
    final qos = context.select<SimulationController, double?>((c) => c.latestDecision?.qosFactor);
    final hf = context.select<SimulationController, double?>((c) => c.latestDecision?.handoverFactor);

    final Color bannerBg = isUnavailable
        ? AppTheme.lightRedBg
        : (isRecommended ? AppTheme.lightGreenBg : Colors.white);

    final Color borderColor = isUnavailable
        ? AppTheme.errorRed
        : (isRecommended ? AppTheme.successGreen : AppTheme.dividerColor);

    final Color tagColor = isUnavailable
        ? AppTheme.errorRed
        : (isRecommended ? AppTheme.successGreen : AppTheme.textSecondary);

    final String tagText = isUnavailable
        ? 'KONEKSI TERPUTUS (OUT OF RANGE)'
        : (isRecommended ? 'REKOMENDASI HANDOVER (OPTIMAL)' : 'KEPUTUSAN SAAT INI (ADVISORY)');

    final String mainTitle = isUnavailable
        ? (targetId != null ? 'TERPUTUS → PINDAH KE $targetId' : 'KONEKSI HILANG: $activeId')
        : (isRecommended ? 'HANDOVER → $targetId' : 'STAY DI JARINGAN $activeId');

    final threshold = context.select<SimulationController, double?>((c) => c.latestDecision?.threshold) ?? 0.70;

    final String subText = isUnavailable
        ? 'Jaringan aktif $activeId tidak terjangkau. Disarankan beralih ke jaringan alternatif.'
        : (isRecommended
            ? 'HF (${hf?.toStringAsFixed(2)}) > Ambang (${threshold.toStringAsFixed(2)}) · Kualitas kanal menurun, target terseleksi.'
            : 'QoS: ${qos != null ? qos.toStringAsFixed(2) : '-'} · HF: ${hf != null ? hf.toStringAsFixed(2) : '-'} (Ambang: ${threshold.toStringAsFixed(2)}) · Sinyal & QoS mencukupi.');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(
          color: borderColor,
          width: (isUnavailable || isRecommended) ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tagText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: tagColor,
                ),
              ),
              if (isRecommended && targetId != null)
                ElevatedButton.icon(
                  icon: Icon(isUnavailable ? Icons.warning_amber : Icons.check, size: 16),
                  label: Text(
                    isUnavailable ? 'Beralih ke $targetId' : 'Terima Handover',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUnavailable ? AppTheme.errorRed : AppTheme.successGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => context.read<SimulationController>().acceptHandover(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            mainTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isUnavailable
                  ? AppTheme.errorRed
                  : (isRecommended ? AppTheme.successGreen : AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subText,
            style: TextStyle(
              fontSize: 12,
              color: isUnavailable ? AppTheme.errorRed : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Kartu Jaringan 4G, 5G, Wi-Fi dengan status sinyal live & indikator jaringan aktif
class _LiveNetworkCardsSectionPlaceholder extends StatelessWidget {
  const _LiveNetworkCardsSectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    final snapshots = context.select<SimulationController, List<NetworkSnapshot>>((c) => c.snapshots);
    final activeId = context.select<SimulationController, String>((c) => c.activeNetworkId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kondisi Sinyal Kanal (4G, 5G, WLAN)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...snapshots.map(
          (s) {
            final isActive = s.id == activeId;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                side: BorderSide(
                  color: isActive ? AppTheme.primaryBlue : AppTheme.dividerColor,
                  width: isActive ? 2.0 : 0.8,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  s.technology == NetworkTechnology.nr
                      ? Icons.five_g
                      : (s.technology == NetworkTechnology.lte ? Icons.four_g_mobiledata : Icons.wifi),
                  color: s.available ? AppTheme.primaryBlue : AppTheme.errorRed,
                  size: 28,
                ),
                title: Row(
                  children: [
                    Text(
                      '${s.id} (${s.technology.name.toUpperCase()})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AKTIF',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  'RSS: ${s.rssDbm.toStringAsFixed(1)} dBm · Rate: ${s.dataRateMbps.toStringAsFixed(1)} Mbps · Delay: ${s.delayMs.toStringAsFixed(1)} ms',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.available ? AppTheme.lightGreenBg : AppTheme.lightRedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.available ? 'IN RANGE' : 'OUT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: s.available ? AppTheme.successGreen : AppTheme.errorRed,
                        ),
                      ),
                    ),
                    if (!isActive && s.available) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.link, size: 18),
                        tooltip: 'Pilih sebagai jaringan aktif',
                        onPressed: () => context.read<SimulationController>().switchActiveNetwork(s.id),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
