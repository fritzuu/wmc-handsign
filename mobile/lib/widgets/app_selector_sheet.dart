import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/application/application.dart';
import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';
import 'app_sla_detail_dialog.dart';

/// Bottom Sheet modal modern dan rapi untuk memilih profil aplikasi spesifik.
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
              Icon(Icons.apps_rounded, size: 20, color: context.textPrimaryColor),
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
                      'Pilih profil untuk mengevaluasi kesesuaian SLA jaringan',
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
          const Divider(height: 20),

          // Daftar Profil Aplikasi Bersih & Ringkas
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

class _AppProfileTile extends StatelessWidget {
  final AppProfile profile;
  final bool isSelected;
  final VoidCallback onSelect;

  const _AppProfileTile({
    required this.profile,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222222) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  profile.icon,
                  size: 20,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 10),
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
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            profile.trafficClass.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _slaSummary(profile),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Tombol Detail Modal SLA & Standar
              OutlinedButton.icon(
                icon: const Icon(Icons.info_outline, size: 12),
                label: const Text(
                  'Detail',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                  side: BorderSide(color: context.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => AppSlaDetailDialog.show(
                  context,
                  profile: profile,
                  isSelected: isSelected,
                  onSelect: onSelect,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppTheme.successGreen,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _slaSummary(AppProfile profile) {
    switch (profile.id) {
      case 'youtube':
        return 'Min 5.0 Mbps · Target 25 Mbps · Delay < 350ms';
      case 'mobile_legends':
        return 'Maks Latensi 60ms · Target 20ms · Loss < 10⁻⁵';
      case 'whatsapp_call':
        return 'Maks Latensi 120ms · Target 50ms · Suara HD';
      case 'cloud_download':
        return 'Throughput Maks (100 Mbps) · Toleran Delay';
      case 'social_media':
        return 'Maks Latensi 200ms · Throughput 15 Mbps';
      default:
        return 'SLA Min ${profile.sla.minDataRateMbps.toStringAsFixed(1)} Mbps · Maks Delay ${profile.sla.maxDelayMs.toStringAsFixed(0)}ms';
    }
  }
}
