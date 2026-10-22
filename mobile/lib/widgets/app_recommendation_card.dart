import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/application/application.dart';
import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';
import 'app_selector_sheet.dart';

/// Kartu rekomendasi jaringan terbaik berdasarkan aplikasi spesifik yang aktif.
class AppRecommendationCard extends StatelessWidget {
  final bool compact;

  const AppRecommendationCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final profile = controller.activeAppProfile;
    final report = controller.currentAppReport;
    final activeId = controller.activeNetworkId;
    final isDark = context.isDark;

    final best = report?.bestCandidate;
    final isCurrentBest = best != null && best.candidate.id == activeId;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Nama Aplikasi & Tombol Ubah
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(profile.icon, size: 18, color: context.textPrimaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aplikasi: ${profile.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Kelas ${profile.trafficClass.name.toUpperCase()} · ${profile.category}',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 14),
                label: const Text('Ganti', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => AppSelectorSheet.show(context),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Konten Rekomendasi Jaringan Terbaik
          if (best != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jaringan Terbaik Saat Ini:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            best.candidate.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isCurrentBest)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge Skor Kesesuaian
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _levelBackgroundColor(best.level),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _levelBorderColor(best.level), width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${best.suitabilityScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _levelTextColor(best.level),
                        ),
                      ),
                      Text(
                        'Kesesuaian',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: _levelTextColor(best.level),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!compact) ...[
              const SizedBox(height: 10),
              // Ringkasan penjelasan (Explainability)
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report!.summary,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Perbandingan Kandidat Jaringan
              Text(
                'Perbandingan Alternatif Jaringan:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.textTertiaryColor,
                ),
              ),
              const SizedBox(height: 6),
              ...report.rankings.map((cand) {
                final isCandActive = cand.candidate.id == activeId;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 85,
                        child: Text(
                          cand.candidate.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCandActive ? FontWeight.bold : FontWeight.normal,
                            color: context.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: cand.suitabilityScore / 100.0,
                            backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                            color: cand.level == SuitabilityLevel.optimal
                                ? context.textPrimaryColor
                                : (cand.level == SuitabilityLevel.acceptable
                                    ? context.textSecondaryColor
                                    : AppTheme.errorRed),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${cand.suitabilityScore.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cand.isSlaViolated ? AppTheme.errorRed : context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Jika jaringan aktif saat ini bukan jaringan terbaik, beri opsi beralih
            if (!isCurrentBest && !controller.isHandoverRecommended) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text('Beralih ke ${best.candidate.displayName}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => controller.switchActiveNetwork(best.candidate.id),
                ),
              ),
            ],
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Memuat data sinyal jaringan...',
                  style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _levelBackgroundColor(SuitabilityLevel level) {
    switch (level) {
      case SuitabilityLevel.optimal:
        return AppTheme.successGreen.withValues(alpha: 0.12);
      case SuitabilityLevel.acceptable:
        return AppTheme.warningOrange.withValues(alpha: 0.12);
      case SuitabilityLevel.violated:
        return AppTheme.errorRed.withValues(alpha: 0.12);
    }
  }

  Color _levelBorderColor(SuitabilityLevel level) {
    switch (level) {
      case SuitabilityLevel.optimal:
        return AppTheme.successGreen.withValues(alpha: 0.35);
      case SuitabilityLevel.acceptable:
        return AppTheme.warningOrange.withValues(alpha: 0.35);
      case SuitabilityLevel.violated:
        return AppTheme.errorRed.withValues(alpha: 0.35);
    }
  }

  Color _levelTextColor(SuitabilityLevel level) {
    switch (level) {
      case SuitabilityLevel.optimal:
        return AppTheme.successGreen;
      case SuitabilityLevel.acceptable:
        return AppTheme.warningOrange;
      case SuitabilityLevel.violated:
        return AppTheme.errorRed;
    }
  }
}
