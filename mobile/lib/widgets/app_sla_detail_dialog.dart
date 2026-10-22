import 'package:flutter/material.dart';
import '../core/application/app_profile.dart';
import '../theme/app_theme.dart';

/// Modal Dialog Detail Spesifikasi SLA & Rujukan Standar Telekomunikasi Resmi (3GPP / ITU-T).
class AppSlaDetailDialog extends StatelessWidget {
  final AppProfile profile;
  final bool isSelected;
  final VoidCallback? onSelect;

  const AppSlaDetailDialog({
    super.key,
    required this.profile,
    this.isSelected = false,
    this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required AppProfile profile,
    bool isSelected = false,
    VoidCallback? onSelect,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppSlaDetailDialog(
        profile: profile,
        isSelected: isSelected,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Dialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Modal
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242424) : const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(profile.icon, size: 24, color: context.textPrimaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                profile.trafficClass.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profile.category,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Standar Acuan Telekomunikasi
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Standar Telekomunikasi Acuan:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            profile.standardReference,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Matriks Parameter SLA
              Text(
                'Parameter Kebutuhan QoS (SLA):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SlaMetricCard(
                      label: 'Throughput',
                      minVal: '${profile.sla.minDataRateMbps.toStringAsFixed(1)} Mbps',
                      targetVal: '${profile.sla.targetDataRateMbps.toStringAsFixed(0)} Mbps',
                      isGoodHigher: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SlaMetricCard(
                      label: 'Latensi (Ping)',
                      minVal: 'Maks ${profile.sla.maxDelayMs.toStringAsFixed(0)} ms',
                      targetVal: '< ${profile.sla.targetDelayMs.toStringAsFixed(0)} ms',
                      isGoodHigher: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SlaSingleMetricRow(
                label: 'Toleransi Bit Error Rate (BER / Loss)',
                value: 'Maks ${profile.sla.maxBer.toStringAsExponential(0)} · Target < ${profile.sla.targetBer.toStringAsExponential(0)}',
              ),

              const SizedBox(height: 14),

              // Penjelasan Ilmiah Mengapa Kebutuhan Ini Berbeda
              Text(
                'Mengapa Kebutuhan Aplikasi Ini Berbeda?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Color(0xFFEAB308),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profile.technicalRationale,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                  if (!isSelected && onSelect != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : AppTheme.darkNavy,
                        foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSelect!();
                      },
                      child: const Text('Pilih Aplikasi Ini'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlaMetricCard extends StatelessWidget {
  final String label;
  final String minVal;
  final String targetVal;
  final bool isGoodHigher;

  const _SlaMetricCard({
    required this.label,
    required this.minVal,
    required this.targetVal,
    required this.isGoodHigher,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 2),
          Text(
            targetVal,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          Text(
            minVal,
            style: TextStyle(fontSize: 9, color: context.textTertiaryColor),
          ),
        ],
      ),
    );
  }
}

class _SlaSingleMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _SlaSingleMetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
