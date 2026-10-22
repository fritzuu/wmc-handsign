import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/handover/models.dart';
import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';

/// Card Pemilih Jaringan Aktif:
/// Memungkinkan pengguna memilih jaringan yang sedang dipakai terlebih dahulu
/// dari opsi jaringan yang sedang dalam jangkauan (in range), kemudian sistem
/// akan memberikan saran/rekomendasi handover jika ada alternatif yang lebih optimal.
class ActiveNetworkSelectorCard extends StatelessWidget {
  const ActiveNetworkSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final isDark = context.isDark;
    final activeId = controller.activeNetworkId;
    final snapshots = controller.snapshots;

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
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Icon(
                    Icons.settings_input_antenna_rounded,
                    size: 18,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Jaringan yang Sedang Kamu Pakai',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Hubungkan ke jaringan dalam jangkauan sinyalmu',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: 10),

            // Daftar Kartu Jaringan
            Column(
              children: snapshots.map((s) {
                final isConnected = s.id == activeId;
                final inRange = s.available;

                final IconData techIcon;
                final Color techColor;
                switch (s.technology) {
                  case NetworkTechnology.wlan:
                    techIcon = Icons.wifi_rounded;
                    techColor = const Color(0xFF10B981);
                    break;
                  case NetworkTechnology.nr:
                    techIcon = Icons.bolt_rounded;
                    techColor = const Color(0xFF8B5CF6);
                    break;
                  case NetworkTechnology.lte:
                  default:
                    techIcon = Icons.cell_tower_rounded;
                    techColor = const Color(0xFF3B82F6);
                    break;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? (isDark
                            ? AppTheme.successGreen.withValues(alpha: 0.12)
                            : AppTheme.lightGreenBg)
                        : (inRange
                            ? context.cardColor
                            : (isDark
                                ? const Color(0xFF161616)
                                : const Color(0xFFF8FAFC))),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isConnected
                          ? AppTheme.successGreen.withValues(alpha: 0.6)
                          : (inRange
                              ? context.borderColor
                              : context.borderColor.withValues(alpha: 0.4)),
                      width: isConnected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Ikon Teknologi
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: inRange
                              ? techColor.withValues(alpha: 0.15)
                              : (isDark
                                  ? const Color(0xFF262626)
                                  : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          techIcon,
                          size: 20,
                          color: inRange ? techColor : context.textTertiaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Detail Jaringan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                Text(
                                  s.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: inRange
                                        ? context.textPrimaryColor
                                        : context.textTertiaryColor,
                                  ),
                                ),
                                if (isConnected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'TERHUBUNG',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  )
                                else if (!inRange)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF450A0A)
                                          : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF7F1D1D)
                                            : const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: Text(
                                      'LUAR JANGKAUAN',
                                      style: TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              inRange
                                  ? '${s.rssDbm.toStringAsFixed(0)} dBm · ${s.dataRateMbps.toStringAsFixed(0)} Mbps · ${s.delayMs.toStringAsFixed(0)} ms · ${s.loadLabel}'
                                  : 'Sinyal tidak terdeteksi dari posisimu',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: inRange
                                    ? context.textSecondaryColor
                                    : context.textTertiaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Hubungkan / Status
                      if (isConnected)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 22,
                            color: AppTheme.successGreen,
                          ),
                        )
                      else if (inRange)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : AppTheme.darkNavy,
                            foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {
                            controller.switchActiveNetwork(s.id);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Terhubung ke ${s.displayName}. Sistem mulai mengevaluasi kondisi jaringan.'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text(
                            'Hubungkan',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textTertiaryColor,
                            side: BorderSide(color: context.borderColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${s.displayName} berada di luar jangkauan sinyal. Dekati pemancar untuk dapat terhubung.'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text(
                            'Luar Jangkauan',
                            style: TextStyle(fontSize: 9.5),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
