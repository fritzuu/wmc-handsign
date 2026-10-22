import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/handover/handover.dart';
import '../core/mobility/mobility.dart';
import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';

/// Card Visualisasi Peta 2D Interaktif: Menampilkan Posisi Pengguna,
/// Jejak Langkah (Trajectory Steps), Jangkauan Sinyal Access Point, dan Garis Koneksi.
class SimulationMapCard extends StatefulWidget {
  const SimulationMapCard({super.key});

  @override
  State<SimulationMapCard> createState() => _SimulationMapCardState();
}

class _SimulationMapCardState extends State<SimulationMapCard> {
  bool _showCoverageCircles = true;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final isDark = context.isDark;
    final stepIndex = controller.stepIndex;
    final userPos = controller.userPosition;
    final isMoving = controller.mobilityState.isMoving;
    final speed = controller.velocityMps;
    final activeId = controller.activeNetworkId;
    final isUnavailable = controller.isActiveNetworkUnavailable;
    final isInObstacle = controller.isUserInObstacleZone;
    final activeScenario = controller.activePresetScenario;

    // Hitung jarak ke node utama
    final distCenter = sqrt(pow(userPos.x - 250.0, 2) + pow(userPos.y - 250.0, 2));
    final distWifi = sqrt(pow(userPos.x - 120.0, 2) + pow(userPos.y - 120.0, 2));
    final isWifiInRange = distWifi <= 100.0;
    final is5gInRange = distCenter <= 350.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Judul, Status & Toggle Coverage
            Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  color: context.textPrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Posisi & Mobilitas Pengguna',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Peta Visualisasi Langkah & Jangkauan Access Point',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge Status Gerak
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMoving
                        ? AppTheme.successGreen.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMoving ? 'MOVING (${speed.toStringAsFixed(1)} m/s)' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isMoving ? AppTheme.successGreen : context.textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _showCoverageCircles ? Icons.radar : Icons.radar_outlined,
                    size: 18,
                    color: _showCoverageCircles ? context.textPrimaryColor : context.textTertiaryColor,
                  ),
                  tooltip: _showCoverageCircles ? 'Sembunyikan Radius Sinyal' : 'Tampilkan Radius Sinyal',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _showCoverageCircles = !_showCoverageCircles;
                    });
                  },
                ),
              ],
            ),

            // Baris 1: Status Konteks Lingkungan & Zona Kampus Aktif
            Builder(
              builder: (context) {
                final Color bannerColor;
                final IconData bannerIcon;
                final String bannerText;

                if (isInObstacle) {
                  bannerColor = AppTheme.errorRed;
                  bannerIcon = Icons.domain_disabled;
                  bannerText = '🏢 NLoS Gedung Beton: 5G Teredam -24dB ➔ 4G Menjadi Penyelamat #1';
                } else if (distWifi <= 70.0) {
                  bannerColor = const Color(0xFF10B981); // Emerald / Teal
                  bannerIcon = Icons.wifi_tethering;
                  bannerText = '☕ Coworking Cafe Hub: Wi-Fi Optimal (Latensi Rendah 8ms, Hemat Biaya)';
                } else if (is5gInRange) {
                  bannerColor = const Color(0xFF6366F1); // Indigo
                  bannerIcon = Icons.visibility;
                  bannerText = '⚡ Tech Plaza Terbuka: LoS Bebas Hambatan (5G Super Cepat ~800+ Mbps)';
                } else {
                  bannerColor = const Color(0xFF3B82F6); // Blue
                  bannerIcon = Icons.directions_walk;
                  bannerText = '🚶 Koridor Mobilitas: Di Bawah Jangkauan Payung Luas 4G LTE';
                }

                return Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: bannerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bannerIcon,
                        size: 13,
                        color: bannerColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bannerText,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: bannerColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Baris 2: Shortcut Uji Skenario 1-Klik
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Uji Skenario:',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondaryColor,
                  ),
                ),
                _ScenarioChip(
                  label: '📶 Wi-Fi Terbaik',
                  isActive: activeScenario == SimulationPresetScenario.wifiOptimal,
                  onTap: () => controller.applyPresetScenario(SimulationPresetScenario.wifiOptimal),
                  isDark: isDark,
                  borderColor: context.borderColor,
                ),
                _ScenarioChip(
                  label: '⚡ 5G Terbaik (LoS)',
                  isActive: activeScenario == SimulationPresetScenario.fiveGLineOfSight,
                  onTap: () => controller.applyPresetScenario(SimulationPresetScenario.fiveGLineOfSight),
                  isDark: isDark,
                  borderColor: context.borderColor,
                ),
                _ScenarioChip(
                  label: '🛡️ 4G Terbaik (Rintangan)',
                  isActive: activeScenario == SimulationPresetScenario.fourGObstacle,
                  onTap: () => controller.applyPresetScenario(SimulationPresetScenario.fourGObstacle),
                  isDark: isDark,
                  borderColor: context.borderColor,
                ),
                _ScenarioChip(
                  label: '🔄 Sirkuit Dinamis',
                  isActive: activeScenario == SimulationPresetScenario.circuitLoop,
                  onTap: () => controller.applyPresetScenario(SimulationPresetScenario.circuitLoop),
                  isDark: isDark,
                  borderColor: context.borderColor,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Canvas Peta 2D
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9),
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: CustomPaint(
                    painter: _SimulationCanvasPainter(
                      userPosition: userPos,
                      history: controller.history,
                      baseStations: controller.baseStations,
                      obstacles: controller.obstacles,
                      isInObstacle: isInObstacle,
                      activeNetworkId: activeId,
                      isUnavailable: isUnavailable,
                      showCoverage: _showCoverageCircles,
                      pattern: controller.mobilityPattern,
                      isDark: isDark,
                      borderColor: context.borderColor,
                      primaryTextColor: context.textPrimaryColor,
                      secondaryTextColor: context.textSecondaryColor,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Indikator Posisi & Jarak Realtime (Responsive LayoutBuilder)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final pills = [
                  _MetricPill(
                    label: 'Posisi Pengguna',
                    value: 'X: ${userPos.x.toStringAsFixed(0)}m, Y: ${userPos.y.toStringAsFixed(0)}m',
                    subValue: 'Langkah #$stepIndex',
                    icon: Icons.person_pin_circle_outlined,
                  ),
                  _MetricPill(
                    label: 'Jarak ke Wi-Fi AP',
                    value: '${distWifi.toStringAsFixed(0)} m',
                    subValue: isWifiInRange ? 'Dalam Radius (100m)' : 'Di Luar Jangkauan',
                    highlightColor: isWifiInRange ? AppTheme.successGreen : AppTheme.errorRed,
                    icon: Icons.wifi,
                  ),
                  _MetricPill(
                    label: 'Jarak ke 4G/5G',
                    value: '${distCenter.toStringAsFixed(0)} m',
                    subValue: is5gInRange ? '5G Terjangkau' : 'Hanya 4G',
                    icon: Icons.cell_tower,
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      pills[0],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: pills[1]),
                          const SizedBox(width: 8),
                          Expanded(child: pills[2]),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: pills[0]),
                    const SizedBox(width: 8),
                    Expanded(child: pills[1]),
                    const SizedBox(width: 8),
                    Expanded(child: pills[2]),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            // Legenda Simbol & Radius
            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _LegendItem(
                  color: isDark ? Colors.white : AppTheme.darkNavy,
                  label: 'User & Jejak',
                  shape: BoxShape.circle,
                ),
                const _LegendItem(
                  color: Color(0xFF8B5CF6), // Ungu
                  label: '5G (Radius 350m)',
                ),
                const _LegendItem(
                  color: Color(0xFF10B981), // Hijau
                  label: 'Wi-Fi AP (Radius 100m)',
                ),
                const _LegendItem(
                  color: Color(0xFF3B82F6), // Biru
                  label: '4G (Area Penuh)',
                ),
                _LegendItem(
                  color: isDark ? const Color(0xFF4A4A4A) : const Color(0xFF94A3B8),
                  label: 'Gedung (NLoS 5G)',
                  shape: BoxShape.rectangle,
                ),
                _LegendItem(
                  color: isUnavailable ? AppTheme.errorRed : (isDark ? Colors.white : AppTheme.darkNavy),
                  label: isUnavailable ? 'Koneksi Terputus' : 'Koneksi Aktif',
                  isLine: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color? highlightColor;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.borderColor),
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
                  style: TextStyle(fontSize: 9.5, color: context.textSecondaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: highlightColor ?? context.textTertiaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final BoxShape shape;
  final bool isLine;

  const _LegendItem({
    required this.color,
    required this.label,
    this.shape = BoxShape.rectangle,
    this.isLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(
            width: 12,
            height: 2,
            color: color,
          )
        else
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: shape,
              borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(2) : null,
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter untuk menggambar peta 2D (500m x 500m)
class _SimulationCanvasPainter extends CustomPainter {
  final MobilityPoint userPosition;
  final List<DecisionRecord> history;
  final List<BaseStationNode> baseStations;
  final List<ObstacleZone> obstacles;
  final bool isInObstacle;
  final String activeNetworkId;
  final bool isUnavailable;
  final bool showCoverage;
  final MobilityPattern pattern;
  final bool isDark;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  _SimulationCanvasPainter({
    required this.userPosition,
    required this.history,
    required this.baseStations,
    required this.obstacles,
    required this.isInObstacle,
    required this.activeNetworkId,
    required this.isUnavailable,
    required this.showCoverage,
    required this.pattern,
    required this.isDark,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));

    const double simSize = 500.0;
    final double scaleX = size.width / simSize;
    final double scaleY = size.height / simSize;

    Offset toCanvas(double x, double y) {
      final safeX = (x.isNaN || x.isInfinite) ? (simSize / 2) : x;
      final safeY = (y.isNaN || y.isInfinite) ? (simSize / 2) : y;
      return Offset(
        safeX.clamp(0.0, simSize) * scaleX,
        safeY.clamp(0.0, simSize) * scaleY,
      );
    }

    // 1. Grid Background (setiap 100 meter)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;

    for (double m = 100.0; m < simSize; m += 100.0) {
      canvas.drawLine(toCanvas(m, 0), toCanvas(m, simSize), gridPaint);
      canvas.drawLine(toCanvas(0, m), toCanvas(simSize, m), gridPaint);
    }

    // 1b. Zona Lingkungan Kampus: Coworking Cafe Hub (Wi-Fi 6 Zone)
    final cafeTopLeft = toCanvas(75.0, 75.0);
    final cafeBottomRight = toCanvas(165.0, 165.0);
    final cafeRect = Rect.fromPoints(cafeTopLeft, cafeBottomRight);
    final cafeFill = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.fill;
    final cafeBorder = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(cafeRect, const Radius.circular(6)), cafeFill);
    canvas.drawRRect(RRect.fromRectAndRadius(cafeRect, const Radius.circular(6)), cafeBorder);
    _drawText(
      canvas,
      '☕ Coworking Cafe Hub',
      Offset(cafeTopLeft.dx + 4, cafeTopLeft.dy + 4),
      7.5,
      const Color(0xFF10B981),
      isBold: true,
    );

    // 1c. Zona Lingkungan Kampus: Tech Plaza LoS (5G Zone)
    final plazaTopLeft = toCanvas(195.0, 190.0);
    final plazaBottomRight = toCanvas(295.0, 280.0);
    final plazaRect = Rect.fromPoints(plazaTopLeft, plazaBottomRight);
    final plazaFill = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: isDark ? 0.07 : 0.04)
      ..style = PaintingStyle.fill;
    final plazaBorder = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(RRect.fromRectAndRadius(plazaRect, const Radius.circular(6)), plazaFill);
    canvas.drawRRect(RRect.fromRectAndRadius(plazaRect, const Radius.circular(6)), plazaBorder);
    _drawText(
      canvas,
      '🌳 Tech Plaza LoS',
      Offset(plazaTopLeft.dx + 4, plazaTopLeft.dy + 4),
      7.5,
      const Color(0xFF6366F1),
      isBold: true,
    );

    // Rintangan Fisik (Obstacle Zones - Gedung Beton NLoS)
    for (final obs in obstacles) {
      final obsTopLeft = toCanvas(obs.x, obs.y);
      final obsBottomRight = toCanvas(obs.x + obs.width, obs.y + obs.height);
      final obsRect = Rect.fromPoints(obsTopLeft, obsBottomRight);

      final obsFill = Paint()
        ..color = isDark ? const Color(0xFF222222) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(obsRect, const Radius.circular(5)), obsFill);

      final obsBorder = Paint()
        ..color = isInObstacle
            ? AppTheme.errorRed.withValues(alpha: 0.7)
            : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(RRect.fromRectAndRadius(obsRect, const Radius.circular(5)), obsBorder);

      // Label Gedung
      _drawText(
        canvas,
        '🏢 ${obs.name}',
        Offset(obsTopLeft.dx + 4, obsTopLeft.dy + 4),
        8.0,
        secondaryTextColor,
        isBold: true,
      );
    }

    // Rute Panduan Sirkuit Loop (Faint Circuit Guide Track)
    if (pattern == MobilityPattern.naturalCircuit) {
      final circuitPaint = Paint()
        ..color = (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final circuitPath = Path();
      final nodes = RandomWaypointGenerator.defaultCircuitNodes;
      final startPt = toCanvas(nodes.first.x, nodes.first.y);
      circuitPath.moveTo(startPt.dx, startPt.dy);
      for (int i = 1; i < nodes.length; i++) {
        final pt = toCanvas(nodes[i].x, nodes[i].y);
        circuitPath.lineTo(pt.dx, pt.dy);
      }
      circuitPath.close();
      canvas.drawPath(circuitPath, circuitPaint);
    }

    // Label koordinat batas (0,0) & (500,500)
    _drawText(canvas, '0,0', const Offset(4, 3), 8.0, secondaryTextColor);
    _drawText(canvas, '500,500', Offset(size.width - 36, size.height - 13), 8.0, secondaryTextColor);
    _drawText(canvas, '100m grid', Offset(size.width - 44, 4), 7.5, secondaryTextColor.withValues(alpha: 0.6));

    // 2. Base Station Nodes & Coverage Radius
    BaseStationNode? activeNode;
    BaseStationNode? wifiNode;
    BaseStationNode? nrNode;
    BaseStationNode? lteNode;

    for (final node in baseStations) {
      if (node.id.toLowerCase() == activeNetworkId.toLowerCase() ||
          formatNetworkLabel(node.id).toLowerCase() == formatNetworkLabel(activeNetworkId).toLowerCase()) {
        activeNode = node;
      }
      if (node.technology == NetworkTechnology.wlan) {
        wifiNode = node;
      } else if (node.technology == NetworkTechnology.nr) {
        nrNode = node;
      } else if (node.technology == NetworkTechnology.lte) {
        lteNode = node;
      }
    }

    // Gambar Jangkauan Sinyal (Coverage Circles)
    if (showCoverage) {
      // a. 4G Umbrella: Indikator area penuh di sekeliling canvas
      if (lteNode != null) {
        final lteBorder = Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
            const Radius.circular(8),
          ),
          lteBorder,
        );
      }

      // b. 5G Hotspot: Radius 350m
      if (nrNode != null) {
        final nrCenter = toCanvas(nrNode.position.x, nrNode.position.y);
        final nrRadius = nrNode.coverageRadiusM * scaleX;
        final nrFill = Paint()
          ..color = const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.08 : 0.09)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(nrCenter, nrRadius, nrFill);

        final nrBorder = Paint()
          ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(nrCenter, nrRadius, nrBorder);
      }

      // c. Wi-Fi AP: Radius 100m
      if (wifiNode != null) {
        final wifiCenter = toCanvas(wifiNode.position.x, wifiNode.position.y);
        final wifiRadius = wifiNode.coverageRadiusM * scaleX;
        final wifiFill = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: isDark ? 0.10 : 0.12)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(wifiCenter, wifiRadius, wifiFill);

        final wifiBorder = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(wifiCenter, wifiRadius, wifiBorder);
      }
    }

    // Gambar Marker Pemancar
    // Wi-Fi AP Marker di (120, 120)
    if (wifiNode != null) {
      final wifiCenter = toCanvas(wifiNode.position.x, wifiNode.position.y);
      final markerPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(wifiCenter, 5.0, markerPaint);

      final markerRing = Paint()
        ..color = isDark ? Colors.black : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(wifiCenter, 5.0, markerRing);

      _drawText(
        canvas,
        'Wi-Fi AP (100m)',
        Offset(wifiCenter.dx + 8, wifiCenter.dy - 6),
        9.5,
        primaryTextColor,
        isBold: true,
        hasBg: true,
        bgColor: isDark ? const Color(0xFF141414).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
      );
    }

    // Pusat Seluler Bersama di (250, 250) (4G Umbrella + 5G Hotspot)
    final cellCenter = toCanvas(250.0, 250.0);
    // Outer ring 4G
    final lteRing = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(cellCenter, 6.0, lteRing);
    // Inner core 5G
    final nrCore = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(cellCenter, 3.5, nrCore);

    _drawText(
      canvas,
      '5G (350m) & 4G Macro',
      Offset(cellCenter.dx + 10, cellCenter.dy - 6),
      9.5,
      primaryTextColor,
      isBold: true,
      hasBg: true,
      bgColor: isDark ? const Color(0xFF141414).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
    );

    // 3. Jejak Langkah (Trajectory Trail) dari riwayat history
    final trailPositions = <Offset>[];
    final safeHistory = List<DecisionRecord>.from(history);
    if (safeHistory.isNotEmpty) {
      final startIndex = max(0, safeHistory.length - 30);
      for (int i = startIndex; i < safeHistory.length; i++) {
        final r = safeHistory[i];
        trailPositions.add(toCanvas(r.userPosition.x, r.userPosition.y));
      }
    }
    // Tambahkan posisi terkini ke akhir trail
    final currentUserCanvasPos = toCanvas(userPosition.x, userPosition.y);
    trailPositions.add(currentUserCanvasPos);

    if (trailPositions.length >= 2) {
      final trailPaint = Paint()
        ..color = (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(trailPositions.first.dx, trailPositions.first.dy);
      for (int i = 1; i < trailPositions.length; i++) {
        path.lineTo(trailPositions[i].dx, trailPositions[i].dy);
      }
      canvas.drawPath(path, trailPaint);

      // Gambar titik-titik langkah di sepanjang lintasan
      for (int i = 0; i < trailPositions.length - 1; i++) {
        final alpha = (0.2 + 0.6 * (i / trailPositions.length)).clamp(0.1, 0.8);
        final dotPaint = Paint()
          ..color = (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(trailPositions[i], 2.0, dotPaint);
      }
    }

    // 4. Garis Koneksi Aktif (User -> Active Base Station / AP)
    if (activeNode != null) {
      final nodeCanvasPos = toCanvas(activeNode.position.x, activeNode.position.y);
      final linkColor = isUnavailable
          ? AppTheme.errorRed
          : (isDark ? Colors.white : AppTheme.darkNavy);

      final linkPaint = Paint()
        ..color = linkColor.withValues(alpha: isUnavailable ? 0.75 : 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isUnavailable ? 1.5 : 1.8;

      canvas.drawLine(currentUserCanvasPos, nodeCanvasPos, linkPaint);

      // Titik tengah garis koneksi dengan indikator
      final midPoint = Offset(
        (currentUserCanvasPos.dx + nodeCanvasPos.dx) / 2,
        (currentUserCanvasPos.dy + nodeCanvasPos.dy) / 2,
      );
      final midDotPaint = Paint()
        ..color = linkColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(midPoint, 2.5, midDotPaint);
    }

    // 5. Posisi Pengguna Terkini (Current User Marker)
    final auraPaint = Paint()
      ..color = (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentUserCanvasPos, 10.0, auraPaint);

    final userRingPaint = Paint()
      ..color = isDark ? Colors.white : AppTheme.darkNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(currentUserCanvasPos, 5.5, userRingPaint);

    final userCorePaint = Paint()
      ..color = isUnavailable
          ? AppTheme.errorRed
          : (isDark ? Colors.white : AppTheme.darkNavy)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentUserCanvasPos, 3.5, userCorePaint);

    // Label user di dekat titik
    final userLabelOffset = Offset(
      (currentUserCanvasPos.dx + 8).clamp(8.0, size.width - 45.0),
      (currentUserCanvasPos.dy + 6).clamp(10.0, size.height - 15.0),
    );
    _drawText(
      canvas,
      'User',
      userLabelOffset,
      9.0,
      isDark ? Colors.white : AppTheme.darkNavy,
      isBold: true,
      hasBg: true,
      bgColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    );

    canvas.restore();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color, {
    bool isBold = false,
    bool hasBg = false,
    Color? bgColor,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    if (hasBg && bgColor != null) {
      final bgRect = Rect.fromLTWH(
        offset.dx - 2,
        offset.dy - 1,
        textPainter.width + 4,
        textPainter.height + 2,
      );
      final bgPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(3)), bgPaint);
    }

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SimulationCanvasPainter oldDelegate) {
    return oldDelegate.userPosition != userPosition ||
        oldDelegate.history.length != history.length ||
        oldDelegate.activeNetworkId != activeNetworkId ||
        oldDelegate.isUnavailable != isUnavailable ||
        oldDelegate.showCoverage != showCoverage ||
        oldDelegate.pattern != pattern ||
        oldDelegate.isInObstacle != isInObstacle ||
        oldDelegate.isDark != isDark;
  }
}

class _ScenarioChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final Color borderColor;

  const _ScenarioChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? Colors.white : AppTheme.darkNavy;
    final activeFg = isDark ? AppTheme.pureBlack : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isActive ? Colors.transparent : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeFg : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}


