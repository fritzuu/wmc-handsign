import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';

/// Card pemilih mode sumber data (Simulasi Kampus vs Live Hardware Sensor)
/// serta penampil metrik fisik jaringan riil saat mode Live aktif.
class LiveTelemetrySourceCard extends StatelessWidget {
  const LiveTelemetrySourceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final isLive = controller.isLiveMode;
    final liveSnapshot = controller.liveSnapshot;
    final isDark = context.isDark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(
          color: isLive ? AppTheme.accentBlue.withOpacity(0.5) : context.borderColor,
          width: isLive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Sumber Data
            Row(
              children: [
                Icon(
                  isLive ? Icons.sensors_rounded : Icons.map_outlined,
                  size: 20,
                  color: isLive ? AppTheme.accentBlue : context.textPrimaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sumber Data Jaringan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        isLive
                            ? 'Telemetri riil dari kartu jaringan perangkat saat ini'
                            : 'Model propagasi HetNet 2D (4G, 5G, Wi-Fi)',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Segmented Mode Selector Button
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2228) : const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeSegmentButton(
                      title: 'Simulasi Kampus',
                      icon: Icons.alt_route_rounded,
                      isActive: !isLive,
                      onTap: () {
                        controller.setDataSourceMode(
                          SimulationDataSourceMode.simulationHetNet,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _ModeSegmentButton(
                      title: 'Live Hardware',
                      icon: Icons.wifi_tethering_rounded,
                      isActive: isLive,
                      isHighlight: true,
                      onTap: () {
                        controller.setDataSourceMode(
                          SimulationDataSourceMode.liveHardwareProbe,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Metrik Live Hardware jika mode live aktif
            if (isLive) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF15191E)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          liveSnapshot.isConnected
                              ? 'PROBE HARDWARE AKTIF'
                              : 'MENCOBA TERHUBUNG...',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          liveSnapshot.networkName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _LiveMetricTile(
                            label: 'Latensi RTT Riil',
                            value: '${liveSnapshot.delayMs.toStringAsFixed(1)} ms',
                            icon: Icons.timer_outlined,
                            isGood: liveSnapshot.delayMs < 50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LiveMetricTile(
                            label: 'Throughput Link',
                            value: '${liveSnapshot.throughputMbps.toStringAsFixed(0)} Mbps',
                            icon: Icons.speed_rounded,
                            isGood: liveSnapshot.throughputMbps > 25,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LiveMetricTile(
                            label: 'Kuat Sinyal',
                            value: '${liveSnapshot.rssDbm.toStringAsFixed(0)} dBm',
                            icon: Icons.signal_cellular_alt_rounded,
                            isGood: liveSnapshot.rssDbm > -70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isHighlight;
  final VoidCallback onTap;

  const _ModeSegmentButton({
    required this.title,
    required this.icon,
    required this.isActive,
    this.isHighlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    Color bg;
    Color fg;

    if (isActive) {
      if (isHighlight) {
        bg = AppTheme.accentBlue;
        fg = Colors.white;
      } else {
        bg = isDark ? const Color(0xFF2E343E) : Colors.white;
        fg = isDark ? Colors.white : Colors.black87;
      }
    } else {
      bg = Colors.transparent;
      fg = context.textSecondaryColor;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isGood;

  const _LiveMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E2228) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.borderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: context.textSecondaryColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isGood ? AppTheme.successGreen : context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
