import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/application/application.dart';
import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';

/// Bottom Sheet modal modern untuk memilih profil aplikasi spesifik.
class AppSelectorSheet extends StatelessWidget {
  const AppSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final activeProfile = controller.activeAppProfile;
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardBorderRadius),
        ),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      padding: EdgeInsets.only(
        top: 12.0,
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.textTertiaryColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Icon(Icons.apps, size: 20, color: context.textPrimaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Aplikasi Spesifik',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Rekomendasi jaringan disesuaikan dengan kebutuhan QoS aplikasi',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
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
          const Divider(height: 24),

          // Daftar Profil Aplikasi
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: AppCatalog.defaultProfiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final profile = AppCatalog.defaultProfiles[index];
                final isSelected = profile.id == activeProfile.id;

                return _AppProfileTile(
                  profile: profile,
                  isSelected: isSelected,
                  onSelect: () {
                    controller.selectAppProfile(profile);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppProfileTile extends StatefulWidget {
  final AppProfile profile;
  final bool isSelected;
  final VoidCallback onSelect;

  const _AppProfileTile({
    required this.profile,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_AppProfileTile> createState() => _AppProfileTileState();
}

class _AppProfileTileState extends State<_AppProfileTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isSelected = widget.isSelected;
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(
          color: isSelected ? context.textPrimaryColor : context.borderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: widget.onSelect,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      profile.icon,
                      size: 20,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                profile.trafficClass.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                          ),
                          maxLines: _expanded ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: context.textSecondaryColor,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: context.textPrimaryColor,
                    ),
                ],
              ),

              // Detail SLA jika di-expand
              if (_expanded) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SlaMetricBadge(
                      label: 'Min / Target Throughput',
                      value: '${profile.sla.minDataRateMbps.toStringAsFixed(1)} / ${profile.sla.targetDataRateMbps.toStringAsFixed(0)} Mbps',
                    ),
                    _SlaMetricBadge(
                      label: 'Max / Target Delay',
                      value: '${profile.sla.maxDelayMs.toStringAsFixed(0)} / ${profile.sla.targetDelayMs.toStringAsFixed(0)} ms',
                    ),
                    _SlaMetricBadge(
                      label: 'Max Toleransi BER',
                      value: profile.sla.maxBer.toStringAsExponential(0),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SlaMetricBadge extends StatelessWidget {
  final String label;
  final String value;

  const _SlaMetricBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, color: context.textTertiaryColor),
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
    );
  }
}
