import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';

/// Screen 6 — Live Monitor Cockpit Shell (Minimalist Black & White)
class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('monitor_scroll_key'),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MonitorPlaybackBar(),
            SizedBox(height: 14),
            _MobilityPositionQuickCard(),
            SizedBox(height: 14),
            _LiveDecisionBannerPlaceholder(),
            SizedBox(height: 14),
            _LiveNetworkCardsSectionPlaceholder(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Bar Kontrol Playback & Kemajuan Simulasi (Monokrom Modern)
class _MonitorPlaybackBar extends StatelessWidget {
  const _MonitorPlaybackBar();

  @override
  Widget build(BuildContext context) {
    final stepIndex = context.select<SimulationController, int>((c) => c.stepIndex);
    final elapsedSeconds = context.select<SimulationController, double>((c) => c.elapsedSeconds);
    final isRunning = context.select<SimulationController, bool>((c) => c.isRunning);
    final currentSpeed = context.select<SimulationController, int>((c) => c.playbackSpeed);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: const BorderSide(color: AppTheme.dividerColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isRunning ? Icons.play_arrow : Icons.pause,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Langkah $stepIndex · ${elapsedSeconds.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRunning
                            ? 'Berjalan (${currentSpeed}x kecepatan)'
                            : 'Simulasi dijeda',
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
                      icon: const Icon(Icons.skip_next, size: 20),
                      tooltip: 'Maju 1s',
                      color: AppTheme.textPrimary,
                      onPressed: () => context.read<SimulationController>().step(1.0),
                    ),
                    IconButton(
                      icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 20),
                      tooltip: isRunning ? 'Jeda' : 'Jalankan',
                      color: AppTheme.textPrimary,
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
                      icon: const Icon(Icons.restart_alt, size: 19),
                      tooltip: 'Reset',
                      color: AppTheme.textSecondary,
                      onPressed: () => context.read<SimulationController>().reset(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
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
                            color: isSelected ? AppTheme.darkNavy : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? AppTheme.darkNavy : AppTheme.dividerColor,
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
                  const SizedBox(width: 8),
                  Container(width: 1, height: 14, color: AppTheme.dividerColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Lompat: ',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  ...[10, 50, 100, 500].map((count) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: InkWell(
                        onTap: () => context.read<SimulationController>().fastForward(count),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Text(
                            '+${count}s',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
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

/// Kartu Cepat Posisi & Kecepatan Pengguna (Monokrom Modern)
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: const BorderSide(color: AppTheme.dividerColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.near_me_outlined, color: AppTheme.textPrimary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Posisi & Mobilitas Pengguna',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Text(
                    isMoving ? 'MOVING' : 'PAUSED',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Koordinat (X, Y)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(pos, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kecepatan Efektif', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(speed, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
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

/// Banner Keputusan Handover Live (High-Contrast Monochrome Banner)
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
    final threshold = context.select<SimulationController, double?>((c) => c.latestDecision?.threshold) ?? 0.45;

    final isAlert = isUnavailable || isRecommended;

    final String tagText = isUnavailable
        ? 'KONEKSI TERPUTUS'
        : (isRecommended ? 'REKOMENDASI HANDOVER' : 'KEPUTUSAN SAAT INI (ADVISORY)');

    final String mainTitle = isUnavailable
        ? (targetId != null ? 'Terputus ➔ Rekomendasi: $targetId' : 'Koneksi Hilang: $activeId')
        : (isRecommended ? 'Pindah ke $targetId' : 'Koneksi Stabil: $activeId');

    final String subText = isUnavailable
        ? 'Jaringan aktif $activeId tidak terjangkau. Disarankan segera beralih ke jaringan cadangan.'
        : (isRecommended
            ? 'HF (${hf?.toStringAsFixed(2)}) > Ambang (${threshold.toStringAsFixed(2)}) · Algoritma merekomendasikan target terbaik.'
            : 'QoS: ${qos != null ? qos.toStringAsFixed(2) : '-'} · HF: ${hf != null ? hf.toStringAsFixed(2) : '-'} (Ambang: ${threshold.toStringAsFixed(2)}) · Sinyal mencukupi.');

    if (isAlert) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          border: Border.all(color: AppTheme.darkBorder, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tagText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (targetId != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.darkNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.read<SimulationController>().acceptHandover(),
                    child: Text(
                      isUnavailable ? 'Beralih ke $targetId' : 'Terima Handover',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              mainTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subText,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: const BorderSide(color: AppTheme.dividerColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tagText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mainTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subText,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section Kartu Jaringan (4G, 5G, Wi-Fi) Monokrom Modern
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...snapshots.map(
          (s) {
            final isActive = s.id == activeId;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                side: BorderSide(
                  color: isActive ? AppTheme.darkNavy : AppTheme.dividerColor,
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Icon(
                  s.technology == NetworkTechnology.nr
                      ? Icons.five_g_outlined
                      : (s.technology == NetworkTechnology.lte ? Icons.cell_tower : Icons.wifi),
                  color: s.available ? AppTheme.textPrimary : AppTheme.textTertiary,
                  size: 24,
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${s.id} (${s.technology.name.toUpperCase()})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.darkNavy,
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
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.available ? AppTheme.surfaceBackground : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: s.available ? AppTheme.dividerColor : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        s.available ? 'IN RANGE' : 'OUT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: s.available ? AppTheme.textPrimary : AppTheme.errorRed,
                        ),
                      ),
                    ),
                    if (!isActive && s.available) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.link, size: 18),
                        tooltip: 'Pilih sebagai jaringan aktif',
                        color: AppTheme.textPrimary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
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
