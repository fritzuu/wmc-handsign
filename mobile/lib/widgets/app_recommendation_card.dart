import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/application/application.dart';
import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';
import 'app_selector_sheet.dart';
import 'circular_percentage_indicator.dart';

/// Kartu rekomendasi jaringan cerdas berbasis aplikasi spesifik yang aktif.
///
/// Menggunakan dropdown seleksi aplikasi yang ringkas, indikator persentase
/// sirkuler yang presisi dan simetris, serta telemetri performa real-time.
class AppRecommendationCard extends StatelessWidget {
  final bool compact;

  const AppRecommendationCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final profile = controller.activeAppProfile;
    final report = controller.currentAppReport;
    final qoe = controller.currentQoE;
    final activeId = controller.activeNetworkId;
    final isDark = context.isDark;
    final isRecommended = controller.isHandoverRecommended;

    final best = report?.bestCandidate;
    final isCurrentBest = best != null && best.candidate.id == activeId;

    // Penentuan palet warna dinamis berbasis status QoE
    final Color qoeColor;
    if (qoe != null) {
      switch (qoe.status) {
        case QoEHealthStatus.pristine:
          qoeColor = const Color(0xFF10B981); // Emerald Green
          break;
        case QoEHealthStatus.good:
          qoeColor = const Color(0xFF3B82F6); // Vibrant Blue
          break;
        case QoEHealthStatus.degraded:
          qoeColor = const Color(0xFFF59E0B); // Amber
          break;
        case QoEHealthStatus.critical:
          qoeColor = const Color(0xFFEF4444); // Crimson Red
          break;
      }
    } else {
      qoeColor = context.textSecondaryColor;
    }

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
          // 1. Profil Aplikasi Aktif & Tombol "Pilih Aplikasi Spesifik"
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        profile.icon,
                        size: 18,
                        color: isDark ? Colors.white : AppTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'SLA: Min ${profile.sla.minDataRateMbps.toStringAsFixed(1)} Mbps · Maks Latensi ${profile.sla.maxDelayMs.toStringAsFixed(0)}ms',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: context.textSecondaryColor,
                            ),
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.tune, size: 13),
                    label: const Text(
                      'Pilih Aplikasi Spesifik',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => AppSelectorSheet.show(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 2. Live QoE Radial Score & Real-App Telemetry HUD (Requirement #1)
          if (qoe != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: qoeColor.withValues(alpha: isDark ? 0.08 : 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: qoeColor.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Percentage Indicator yang simetris, presisi & proporsional
                      CircularPercentageIndicator(
                        percentage: qoe.score,
                        size: 58.0,
                        strokeWidth: 5.5,
                        progressColor: qoeColor,
                        subtitle: 'QoE',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              qoe.statusTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: qoeColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              qoe.statusDescription,
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1.3,
                                color: context.textSecondaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Telemetry Status Pills
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                qoe.telemetry.metricPrimaryLabel,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: context.textTertiaryColor,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                qoe.telemetry.metricPrimaryValue,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: qoe.telemetry.isAlertActive
                                      ? AppTheme.errorRed
                                      : context.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                qoe.telemetry.metricSecondaryLabel,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: context.textTertiaryColor,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                qoe.telemetry.metricSecondaryValue,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // 3. Status Rekomendasi Jaringan Terbaik
          if (best != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendasi Jaringan Terbaik:',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              best.candidate.displayName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: context.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isCurrentBest)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 8,
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
                // Badge Skor Kesesuaian SLA Ringkas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _levelBackgroundColor(best.level),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _levelBorderColor(best.level), width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${best.suitabilityScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _levelTextColor(best.level),
                        ),
                      ),
                      Text(
                        'SLA Match',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: _levelTextColor(best.level),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Banner Proyeksi Peningkatan Handover
            if (isRecommended && qoe?.handoverBenefitText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch, size: 14, color: AppTheme.successGreen),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        qoe!.handoverBenefitText!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => controller.acceptHandover(),
                      child: const Text('Pindah'),
                    ),
                  ],
                ),
              ),
            ],

            if (!compact) ...[
              const SizedBox(height: 10),
              // Perbandingan Alternatif Jaringan
              Text(
                'Perbandingan Alternatif Sinyal:',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: context.textTertiaryColor,
                ),
              ),
              const SizedBox(height: 6),
              ...report!.rankings.map((cand) {
                final isCandActive = cand.candidate.id == activeId;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          cand.candidate.displayName,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isCandActive ? FontWeight.bold : FontWeight.normal,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
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
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${cand.suitabilityScore.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 9.5,
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
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // 4. Mini Head-to-Head Stats Banner
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: AppTheme.successGreen),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${controller.preventedPingPongCount} Ping-Pong Dicegah',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined, size: 12, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${controller.cellularDataSavedMb.toStringAsFixed(1)} MB Dihemat',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _levelBackgroundColor(SuitabilityLevel level) {
    switch (level) {
      case SuitabilityLevel.optimal:
        return AppTheme.successGreen.withValues(alpha: 0.15);
      case SuitabilityLevel.acceptable:
        return const Color(0xFFEAB308).withValues(alpha: 0.15);
      case SuitabilityLevel.violated:
        return AppTheme.errorRed.withValues(alpha: 0.15);
    }
  }

  Color _levelBorderColor(SuitabilityLevel level) {
    switch (level) {
      case SuitabilityLevel.optimal:
        return AppTheme.successGreen.withValues(alpha: 0.5);
      case SuitabilityLevel.acceptable:
        return const Color(0xFFEAB308).withValues(alpha: 0.5);
      case SuitabilityLevel.violated:
        return AppTheme.errorRed.withValues(alpha: 0.5);
    }
  }

  Color _levelTextColor(SuitabilityLevel level) {
    switch (level) {
      case SuitabilityLevel.optimal:
        return AppTheme.successGreen;
      case SuitabilityLevel.acceptable:
        return const Color(0xFFEAB308);
      case SuitabilityLevel.violated:
        return AppTheme.errorRed;
    }
  }
}
