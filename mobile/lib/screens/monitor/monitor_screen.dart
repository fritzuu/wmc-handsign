import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/algorithm_vs_baseline_card.dart';
import '../../widgets/app_recommendation_card.dart';
import '../../widgets/live_telemetry_source_card.dart';
import '../../widgets/simulation_map_card.dart';

/// Screen 6 — Cockpit Monitor Simulasi (Real-Time Playback & Sinyal RF Monokrom)
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
            LiveTelemetrySourceCard(),
            SizedBox(height: 14),
            _PlaybackControlsCard(),
            SizedBox(height: 14),
            SimulationMapCard(),
            SizedBox(height: 14),
            AppRecommendationCard(),
            SizedBox(height: 14),
            AlgorithmVsBaselineCard(),
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

/// Card Kontrol Playback (Step, Play/Pause, Reset, Speed, Lompatan)
class _PlaybackControlsCard extends StatelessWidget {
  const _PlaybackControlsCard();

  @override
  Widget build(BuildContext context) {
    final stepIndex = context.select<SimulationController, int>((c) => c.stepIndex);
    final elapsedSeconds = context.select<SimulationController, double>((c) => c.elapsedSeconds);
    final isRunning = context.select<SimulationController, bool>((c) => c.isRunning);
    final currentSpeed = context.select<SimulationController, int>((c) => c.playbackSpeed);
    final isDark = context.isDark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isRunning ? Icons.play_arrow : Icons.pause,
                  color: context.textPrimaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Langkah $stepIndex · ${elapsedSeconds.toStringAsFixed(1)}s',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRunning
                            ? 'Berjalan (${currentSpeed}x kecepatan)'
                            : 'Simulasi dijeda',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondaryColor,
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
                      color: context.textPrimaryColor,
                      onPressed: () => context.read<SimulationController>().step(1.0),
                    ),
                    IconButton(
                      icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 20),
                      tooltip: isRunning ? 'Jeda' : 'Jalankan',
                      color: context.textPrimaryColor,
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
                      color: context.textSecondaryColor,
                      onPressed: () => context.read<SimulationController>().reset(),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 18, color: context.borderColor),
            Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    'Speed:',
                    style: TextStyle(fontSize: 11, color: context.textSecondaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [1, 2, 5, 10, 20].map((s) {
                      final isSelected = currentSpeed == s;
                      final activeBg = isDark ? Colors.white : AppTheme.darkNavy;
                      final activeFg = isDark ? AppTheme.pureBlack : Colors.white;

                      return InkWell(
                        onTap: () => context.read<SimulationController>().setPlaybackSpeed(s),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? activeBg : context.cardColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? activeBg : context.borderColor,
                            ),
                          ),
                          child: Text(
                            '${s}x',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? activeFg : context.textPrimaryColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    'Lompat:',
                    style: TextStyle(fontSize: 11, color: context.textSecondaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [10, 50, 100, 500].map((count) {
                      return InkWell(
                        onTap: () => context.read<SimulationController>().fastForward(count),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F1F1F) : AppTheme.surfaceBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Text(
                            '+${count}s',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
    final activeDisplayName = context.select<SimulationController, String>((c) => c.activeNetworkDisplayName);
    final isUnavailable = context.select<SimulationController, bool>((c) => c.isActiveNetworkUnavailable);
    final isRecommended = context.select<SimulationController, bool>((c) => c.isHandoverRecommended);
    final targetDisplayName = context.select<SimulationController, String?>((c) => c.recommendedTargetDisplayName);
    final targetId = context.select<SimulationController, String?>((c) => c.recommendedTargetId);
    final qos = context.select<SimulationController, double?>((c) => c.latestDecision?.qosFactor);
    final hf = context.select<SimulationController, double?>((c) => c.latestDecision?.handoverFactor);
    final threshold = context.select<SimulationController, double?>((c) => c.latestDecision?.threshold) ?? 0.45;

    final isAlert = isUnavailable || isRecommended;
    final isDark = context.isDark;

    final String tagText = isUnavailable
        ? 'KONEKSI TERPUTUS'
        : (isRecommended ? 'REKOMENDASI HANDOVER' : 'KEPUTUSAN SAAT INI (ADVISORY)');

    final String mainTitle = isUnavailable
        ? (targetDisplayName != null ? 'Terputus ➔ Rekomendasi: $targetDisplayName' : 'Koneksi Hilang: $activeDisplayName')
        : (isRecommended && targetDisplayName != null ? 'Pindah ke $targetDisplayName' : 'Koneksi Stabil: $activeDisplayName');

    final String subText = isUnavailable
        ? 'Jaringan aktif $activeDisplayName tidak terjangkau. Disarankan segera beralih ke jaringan cadangan.'
        : (isRecommended
            ? 'HF (${hf?.toStringAsFixed(2)}) > Ambang (${threshold.toStringAsFixed(2)}) · Algoritma merekomendasikan target terbaik.'
            : 'QoS: ${qos != null ? qos.toStringAsFixed(2) : '-'} · HF: ${hf != null ? hf.toStringAsFixed(2) : '-'} (Ambang: ${threshold.toStringAsFixed(2)}) · Sinyal mencukupi.');

    if (isAlert) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : AppTheme.darkNavy,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.darkBorder, width: 1.0),
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
                      isUnavailable ? 'Beralih ke $targetDisplayName' : 'Terima Handover',
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
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tagText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mainTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subText,
              style: TextStyle(
                fontSize: 11.5,
                color: context.textSecondaryColor,
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
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Pilih Jaringan yang Sedang Dipakai',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            Text(
              'Tap untuk menghubungkan',
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...snapshots.map(
          (s) {
            final isActive = s.id == activeId;
            final activeBorderColor = isDark ? Colors.white : AppTheme.darkNavy;
            final activeBadgeColor = isDark ? Colors.white : AppTheme.darkNavy;
            final activeBadgeText = isDark ? AppTheme.pureBlack : Colors.white;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                side: BorderSide(
                  color: isActive ? activeBorderColor : context.borderColor,
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                dense: true,
                onTap: (!isActive && s.available)
                    ? () {
                        context.read<SimulationController>().switchActiveNetwork(s.id);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Terhubung ke ${s.displayName}. Sistem mulai mengevaluasi kondisi jaringan.'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Icon(
                  s.technology == NetworkTechnology.nr
                      ? Icons.five_g_outlined
                      : (s.technology == NetworkTechnology.lte ? Icons.cell_tower : Icons.wifi),
                  color: s.available ? context.textPrimaryColor : context.textTertiaryColor,
                  size: 24,
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        s.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: context.textPrimaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: activeBadgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AKTIF',
                          style: TextStyle(color: activeBadgeText, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  'RSS: ${s.rssDbm.toStringAsFixed(1)} dBm · Rate: ${s.dataRateMbps.toStringAsFixed(1)} Mbps · Delay: ${s.delayMs.toStringAsFixed(1)} ms',
                  style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.available
                            ? (isDark ? const Color(0xFF1F2937) : AppTheme.surfaceBackground)
                            : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: s.available
                              ? context.borderColor
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                        ),
                      ),
                      child: Text(
                        s.available ? 'TERJANGKAU' : 'LUAR JANGKAUAN',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: s.available ? context.textPrimaryColor : AppTheme.errorRed,
                        ),
                      ),
                    ),
                    if (!isActive && s.available) ...[
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : AppTheme.darkNavy,
                          foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          context.read<SimulationController>().switchActiveNetwork(s.id);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Terhubung ke ${s.displayName}. Sistem mulai mengevaluasi kondisi jaringan.'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Pakai', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
