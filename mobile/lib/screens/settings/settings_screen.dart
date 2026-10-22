import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/application/application.dart';
import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/app_selector_sheet.dart';

/// Screen 7 — Pengaturan & Konfigurasi Parameter (Monokrom Modern & Dark Mode)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('settings_scroll_key'),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ThemeSelectorSection(),
            SizedBox(height: 16),
            _TrafficClassSelectorSection(),
            SizedBox(height: 16),
            _SimulationParametersSection(),
            SizedBox(height: 16),
            _FuzzyTopsisSummaryCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Bagian Pengaturan Tema Tampilan Aplikasi (Sistem, Terang, Gelap)
class _ThemeSelectorSection extends StatelessWidget {
  const _ThemeSelectorSection();

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final currentMode = themeController.themeMode;
    final isDark = context.isDark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: context.textPrimaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tema Tampilan Aplikasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih estetika tampilan antarmuka monokrom modern:',
              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ThemeChip(
                  label: 'Sistem',
                  icon: Icons.brightness_auto,
                  selected: currentMode == ThemeMode.system,
                  onSelected: () => themeController.setThemeMode(ThemeMode.system),
                  isDark: isDark,
                ),
                _ThemeChip(
                  label: 'Terang',
                  icon: Icons.light_mode_outlined,
                  selected: currentMode == ThemeMode.light,
                  onSelected: () => themeController.setThemeMode(ThemeMode.light),
                  isDark: isDark,
                ),
                _ThemeChip(
                  label: 'Gelap',
                  icon: Icons.dark_mode_outlined,
                  selected: currentMode == ThemeMode.dark,
                  onSelected: () => themeController.setThemeMode(ThemeMode.dark),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;
  final bool isDark;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark ? Colors.white : AppTheme.darkNavy;
    final selectedText = isDark ? AppTheme.pureBlack : Colors.white;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: selected ? selectedText : context.textPrimaryColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? selectedText : context.textPrimaryColor,
        ),
      ),
      selected: selected,
      selectedColor: selectedBg,
      backgroundColor: context.cardColor,
      side: BorderSide(
        color: selected ? selectedBg : context.borderColor,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _TrafficClassSelectorSection extends StatelessWidget {
  const _TrafficClassSelectorSection();

  @override
  Widget build(BuildContext context) {
    final currentClass = context.select<SimulationController, TrafficClass>(
      (c) => c.trafficClass,
    );
    final currentThreshold = context.select<SimulationController, double>(
      (c) => c.currentThreshold,
    );
    final activeProfile = context.select<SimulationController, AppProfile>(
      (c) => c.activeAppProfile,
    );
    final isDark = context.isDark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: context.textPrimaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kelas Aplikasi Aktif (User Preference)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Profil Aplikasi Terpilih
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.borderColor, width: 1.0),
              ),
              child: Row(
                children: [
                  Icon(activeProfile.icon, size: 16, color: context.textPrimaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeProfile.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SLA: Min ${activeProfile.sla.minDataRateMbps.toStringAsFixed(1)} Mbps · Max Delay ${activeProfile.sla.maxDelayMs.toStringAsFixed(0)} ms',
                          style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 12),
                    label: const Text('Ganti', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => AppSelectorSheet.show(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Pilih jenis trafik untuk mengubah prioritas bobot TOPSIS dan ambang Fuzzy:',
              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: TrafficClass.values.map((tc) {
                final isSelected = tc == currentClass;
                final chipSelectedBg = isDark ? Colors.white : AppTheme.darkNavy;
                final chipSelectedText = isDark ? AppTheme.pureBlack : Colors.white;

                return ChoiceChip(
                  label: Text(
                    tc.name[0].toUpperCase() + tc.name.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? chipSelectedText : context.textPrimaryColor,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: chipSelectedBg,
                  backgroundColor: context.cardColor,
                  side: BorderSide(
                    color: isSelected ? chipSelectedBg : context.borderColor,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SimulationController>().setTrafficClass(tc);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Divider(color: context.borderColor),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ambang Inisiasi Handover (Threshold):',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentThreshold.toStringAsFixed(2),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: isDark ? Colors.white : AppTheme.darkNavy,
                inactiveTrackColor: context.borderColor,
                thumbColor: isDark ? Colors.white : AppTheme.darkNavy,
                overlayColor: (isDark ? Colors.white : AppTheme.darkNavy).withValues(alpha: 0.1),
              ),
              child: Slider(
                value: currentThreshold,
                min: 0.30,
                max: 0.85,
                divisions: 11,
                label: currentThreshold.toStringAsFixed(2),
                onChanged: (val) {
                  context.read<SimulationController>().setThreshold(val);
                },
              ),
            ),
            Text(
              'Handover terpicu jika Handover Factor > ${currentThreshold.toStringAsFixed(2)}. Nilai lebih rendah = lebih sensitif.',
              style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulationParametersSection extends StatelessWidget {
  const _SimulationParametersSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map_outlined, color: context.textPrimaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Parameter Lingkungan Simulasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 18, color: context.borderColor),
            const _InfoRow(label: 'Dimensi Area', value: '500m × 500m (Boundary Clamped)'),
            const SizedBox(height: 6),
            const _InfoRow(label: 'Jaringan Heterogen', value: '4G, 5G, dan Wi-Fi (WLAN)'),
            const SizedBox(height: 6),
            const _InfoRow(label: 'Interval Evaluasi', value: '1.0 detik / tick'),
            const SizedBox(height: 6),
            const _InfoRow(label: 'Model Mobilitas', value: 'Random Waypoint Model (RWP)'),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Simulasi dengan Seed Baru', style: TextStyle(fontSize: 11.5)),
              onPressed: () {
                context.read<SimulationController>().reset(newSeed: DateTime.now().millisecondsSinceEpoch);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulasi berhasil di-reset dengan seed baru.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FuzzyTopsisSummaryCard extends StatelessWidget {
  const _FuzzyTopsisSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: context.textPrimaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arsitektur Keputusan Dua Tahap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1. Tahap Inisiasi (Fuzzy Logic):\n'
              '   Menghitung QoS Factor (FIS 1) dan Handover Factor (FIS 2).\n'
              '   Jika Handover Factor > Ambang, seleksi target diaktifkan.\n\n'
              '2. Tahap Seleksi Jaringan (TOPSIS):\n'
              '   Melakukan perangkingan kandidat terbaik berdasarkan bobot AHP kelas trafik aktif.\n\n'
              '3. Penstabil Rekomendasi (Dwell & Hysteresis):\n'
              '   Memastikan target bertahan selama dwell time (3s) dengan gain skor >= 0.05 untuk mengeliminasi efek ping-pong.',
              style: TextStyle(fontSize: 11, color: context.textSecondaryColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.textSecondaryColor)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
          ),
        ),
      ],
    );
  }
}
