import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Komponen visualizer lingkaran persentase yang presisi, simetris, dan responsif.
///
/// Menyelesaikan masalah CircularProgressIndicator bawaan Flutter yang sering
/// overlap atau memotong teks persentase di tengahnya.
class CircularPercentageIndicator extends StatelessWidget {
  /// Nilai persentase [0.0 - 100.0]
  final double percentage;

  /// Diameter lingkaran (lebar & tinggi sama persis)
  final double size;

  /// Ketebalan garis progress (stroke width)
  final double strokeWidth;

  /// Warna busur progress utama
  final Color progressColor;

  /// Warna track latar belakang
  final Color? trackColor;

  /// Label sekunder di bawah angka (opsional, misal: 'QoE' atau 'Match')
  final String? subtitle;

  /// Gaya teks angka utama
  final TextStyle? textStyle;

  /// Gaya teks label sekunder
  final TextStyle? subtitleStyle;

  const CircularPercentageIndicator({
    super.key,
    required this.percentage,
    this.size = 64.0,
    this.strokeWidth = 6.0,
    required this.progressColor,
    this.trackColor,
    this.subtitle,
    this.textStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTrackColor = trackColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08));

    final normalized = (percentage / 100.0).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track & Progress Arc via CustomPainter
          CustomPaint(
            size: Size(size, size),
            painter: _PercentageRingPainter(
              progress: normalized,
              strokeWidth: strokeWidth,
              progressColor: progressColor,
              trackColor: effectiveTrackColor,
            ),
          ),
          // Centered Text Content (Strictly Padded & Centered inside the inner clear area)
          Padding(
            padding: EdgeInsets.all(strokeWidth + 2.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: textStyle ??
                        TextStyle(
                          fontSize: size * 0.28,
                          fontWeight: FontWeight.w900,
                          color: progressColor,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 1.5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      subtitle!,
                      style: subtitleStyle ??
                          TextStyle(
                            fontSize: size * 0.16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.6),
                            height: 1.0,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentageRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  _PercentageRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius dihitung dari tengah lingkaran dikurangi setengah ketebalan garis
    // agar garis progress tidak pernah terpotong boundary widget
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2.0;

    if (radius <= 0) return;

    // 1. Gambar Background Track Lingkaran Penuh (360 derajat)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Gambar Progress Arc (Mulai dari jam 12 / -pi/2 searah jarum jam)
    if (progress > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Jam 12
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PercentageRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
