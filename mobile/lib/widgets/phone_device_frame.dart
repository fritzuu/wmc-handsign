import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Komponen bingkai smartphone realistis dengan Dynamic Island,
/// tombol hardware samping, dan rasio aspek standar smartphone flagship.
///
/// Dirancang untuk tampilan desktop macOS/Web agar terlihat seperti perangkat seluler nyata.
class PhoneDeviceFrame extends StatefulWidget {
  final Widget child;

  const PhoneDeviceFrame({
    super.key,
    required this.child,
  });

  @override
  State<PhoneDeviceFrame> createState() => _PhoneDeviceFrameState();
}

class _PhoneDeviceFrameState extends State<PhoneDeviceFrame> {
  bool _isFrameEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Pada perangkat mobile fisik sungguhan (layar sempit < 550px), matikan frame otomatis
    final screenSize = MediaQuery.of(context).size;
    final isDesktopPlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    final shouldShowFrame = _isFrameEnabled &&
        (isDesktopPlatform || kIsWeb) &&
        screenSize.width > 550 &&
        screenSize.height > 650;

    if (!shouldShowFrame) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dimensi smartphone modern (Rasio ~19.5:9, misal iPhone 15 Pro)
    const phoneWidth = 393.0;
    const phoneHeight = 852.0;
    const phoneRadius = 46.0;
    const bezelThickness = 12.0;

    // Hitung faktor skala otomatis agar pas di layar laptop (MacBook 13"/14")
    final maxAvailableHeight = screenSize.height - 70.0;
    final scale = (maxAvailableHeight / (phoneHeight + bezelThickness * 2))
        .clamp(0.65, 1.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFE9EDF2),
      body: Stack(
        children: [
          // 1. Tombol Kontrol Mengambang di Pojok Atas Layar Desktop
          Positioned(
            top: 14,
            right: 18,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smartphone_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bingkai HP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: _isFrameEnabled,
                      activeColor: AppTheme.accentBlue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        setState(() {
                          _isFrameEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Chassis Smartphone di Tengah Layar
          Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(phoneRadius + bezelThickness),
                  boxShadow: [
                    // Bayangan Luar 3D Realistis
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.65 : 0.25),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tombol Fisik Samping (Hardware Buttons)
                    // Tombol Power (Kanan)
                    Positioned(
                      right: -3,
                      top: 180,
                      child: Container(
                        width: 3.5,
                        height: 75,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF33373E) : const Color(0xFF8A92A0),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Action Button (Kiri)
                    Positioned(
                      left: -3,
                      top: 140,
                      child: Container(
                        width: 3.5,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF33373E) : const Color(0xFF8A92A0),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Volume Up (Kiri)
                    Positioned(
                      left: -3,
                      top: 190,
                      child: Container(
                        width: 3.5,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF33373E) : const Color(0xFF8A92A0),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Volume Down (Kiri)
                    Positioned(
                      left: -3,
                      top: 255,
                      child: Container(
                        width: 3.5,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF33373E) : const Color(0xFF8A92A0),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Bezel Luar Smartphone (Titanium / Slate Border)
                    Container(
                      padding: const EdgeInsets.all(bezelThickness),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2228) : const Color(0xFFD6DBE2),
                        borderRadius: BorderRadius.circular(phoneRadius + bezelThickness),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E343E) : const Color(0xFFFFFFFF),
                          width: 1.5,
                        ),
                      ),
                      child: Container(
                        width: phoneWidth,
                        height: phoneHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(phoneRadius),
                          border: Border.all(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(phoneRadius - 2),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Layar Aplikasi Utama (MediaQuery disesuaikan dengan dimensi HP)
                              MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  size: const Size(phoneWidth, phoneHeight),
                                  padding: const EdgeInsets.only(top: 48, bottom: 20),
                                  viewPadding: const EdgeInsets.only(top: 48, bottom: 20),
                                ),
                                child: widget.child,
                              ),

                              // Dynamic Island di Atas Layar
                              const Positioned(
                                top: 11,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _DynamicIslandPill(),
                                ),
                              ),

                              // Home Indicator Bar di Bawah Layar
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 135,
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pil Dynamic Island interaktif dengan sensor kamera dan lensa depan.
class _DynamicIslandPill extends StatefulWidget {
  const _DynamicIslandPill();

  @override
  State<_DynamicIslandPill> createState() => _DynamicIslandPillState();
}

class _DynamicIslandPillState extends State<_DynamicIslandPill> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        height: _isExpanded ? 52.0 : 31.0,
        width: _isExpanded ? 240.0 : 124.0,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isExpanded
              ? Row(
                  key: const ValueKey('expanded_island'),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_tethering, color: AppTheme.successGreen, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'WMC HetNet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '5G NR',
                            style: TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildCameraHole(),
                      ],
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('compact_island'),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sensor / Mic slit
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF141416),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Kamera Depan (Selfie Lens) dengan aksen optik biru gelap
                    _buildCameraHole(),
                  ],
                ),
        ),
      ),
    );
  }

  static Widget _buildCameraHole() {
    return Container(
      width: 11.5,
      height: 11.5,
      decoration: BoxDecoration(
        color: const Color(0xFF070B12),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1E2838),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Container(
          width: 4.5,
          height: 4.5,
          decoration: const BoxDecoration(
            color: Color(0xFF1A3860),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
