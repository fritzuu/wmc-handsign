import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';

/// Screens 3, 4, 5 — Konfigurasi Eksperimen, Fuzzy, & Bobot TOPSIS (PRD v1.0/v2.0)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('settings_scroll_key'),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TrafficClassSelectorSection(),
            SizedBox(height: 20),
            _SimulationParametersSection(),
            SizedBox(height: 20),
            _FuzzyTopsisSummaryCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kelas Aplikasi Aktif (User Preference)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih jenis trafik untuk mengubah prioritas bobot TOPSIS dan ambang Fuzzy:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TrafficClass.values.map((tc) {
                final isSelected = tc == currentClass;
                return ChoiceChip(
                  label: Text(
                    tc.name[0].toUpperCase() + tc.name.substring(1),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryBlue,
                  backgroundColor: AppTheme.surfaceBackground,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SimulationController>().setTrafficClass(tc);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ambang Inisiasi Handover (Threshold):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  currentThreshold.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ],
            ),
            Slider(
              value: currentThreshold,
              min: 0.30,
              max: 0.85,
              divisions: 11,
              label: currentThreshold.toStringAsFixed(2),
              onChanged: (val) {
                context.read<SimulationController>().setThreshold(val);
              },
            ),
            Text(
              'Handover terpicu jika Handover Factor > ${currentThreshold.toStringAsFixed(2)}. Nilai lebih rendah = lebih sensitif/proaktif.',
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Parameter Lingkungan Simulasi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const _InfoRow(label: 'Dimensi Area', value: '500m × 500m (Boundary Clamped)'),
            const SizedBox(height: 8),
            const _InfoRow(label: 'Jaringan Heterogen', value: '4G LTE Macro, 5G NR Small Cell, WLAN AP'),
            const SizedBox(height: 8),
            const _InfoRow(label: 'Interval Evaluasi', value: '1.0 detik / tick'),
            const SizedBox(height: 8),
            const _InfoRow(label: 'Model Mobilitas', value: 'Random Waypoint Model (RWP)'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset Simulasi dengan Seed Baru'),
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
      color: AppTheme.lightBlueBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_graph, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arsitektur Keputusan Dua Tahap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Tahap Inisiasi (Fuzzy Logic):\n'
              '   Menghitung QoS Factor (FIS 1) dan Handover Factor (FIS 2).\n'
              '   Jika Handover Factor > Ambang, seleksi target diaktifkan.\n\n'
              '2. Tahap Seleksi Jaringan (TOPSIS):\n'
              '   Melakukan perangkingan kandidat terbaik berdasarkan bobot AHP kelas trafik aktif.\n\n'
              '3. Penstabil Rekomendasi (Dwell & Hysteresis):\n'
              '   Memastikan target bertahan selama dwell time (3s) dengan gain skor >= 0.05 untuk mengeliminasi efek ping-pong.',
              style: TextStyle(fontSize: 11, color: AppTheme.deepNavy, height: 1.4),
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
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
