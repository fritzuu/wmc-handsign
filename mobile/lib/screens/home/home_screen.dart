import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_recommendation_card.dart';

/// Screen 2 — Home Dashboard (Minimalist Black & White)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('home_scroll_key'),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SimulationStatusHeroCard(),
            SizedBox(height: 16),
            AppRecommendationCard(compact: true),
            SizedBox(height: 16),
            _SimulatorWorkflowSection(),
            SizedBox(height: 22),
            _MainMenuGridSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Kartu Hero Status Terakhir (Desain Monokrom Modern)
class _SimulationStatusHeroCard extends StatelessWidget {
  const _SimulationStatusHeroCard();

  @override
  Widget build(BuildContext context) {
    final isRunning = context.select<SimulationController, bool>((c) => c.isRunning);
    final stepIndex = context.select<SimulationController, int>((c) => c.stepIndex);
    final activeDisplayName = context.select<SimulationController, String>((c) => c.activeNetworkDisplayName);
    final isUnavailable = context.select<SimulationController, bool>((c) => c.isActiveNetworkUnavailable);
    final isRecommended = context.select<SimulationController, bool>((c) => c.isHandoverRecommended);
    final targetDisplayName = context.select<SimulationController, String?>((c) => c.recommendedTargetDisplayName);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: AppTheme.darkBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isRunning ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRunning ? 'SIMULASI AKTIF' : 'TERJEDA / STANDBY',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Langkah $stepIndex',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isUnavailable
                ? 'Koneksi Terputus: $activeDisplayName'
                : (isRecommended ? 'Rekomendasi: Pindah ke $targetDisplayName' : 'Koneksi Stabil: $activeDisplayName'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isUnavailable
                ? 'Sinyal $activeDisplayName terputus. Sistem menyiapkan perpindahan darurat.'
                : (isRecommended
                    ? 'Algoritma mendeteksi alternatif dengan performa lebih optimal.'
                    : 'Kanal memenuhi kebutuhan QoS profil aplikasi saat ini.'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  size: 16,
                  color: AppTheme.darkNavy,
                ),
                label: Text(
                  isRunning ? 'Jeda' : 'Lanjutkan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNavy,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  final controller = context.read<SimulationController>();
                  if (controller.isRunning) {
                    controller.pause();
                  } else {
                    controller.start();
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.fast_forward, size: 14, color: Colors.white),
                label: const Text(
                  '+100s',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.read<SimulationController>().fastForward(100),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.speed, size: 14, color: Colors.white),
                label: const Text(
                  'Monitor',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.go('/monitor'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Alur Simulator 5 Tahap (Pipeline Vertikal Modern Bebas Cutoff)
class _SimulatorWorkflowSection extends StatelessWidget {
  const _SimulatorWorkflowSection();

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 16,
                        color: context.textPrimaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alur Simulator Vertical Handover',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    '5 TAHAP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pipeline pengambilan keputusan algoritma Ndegwa et al. (2023):',
              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 14),
            const _PipelineStepItem(
              stepNumber: '01',
              title: 'Generator Mobilitas & RF',
              subtitle: 'Simulasi mobilitas RWP & Path Loss kanal 4G/5G/Wi-Fi',
              icon: Icons.cell_tower,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '02',
              title: 'Normalisasi QoS Factor',
              subtitle: 'Evaluasi Throughput, Latensi/Delay, dan Packet Loss/BER',
              icon: Icons.calculate_outlined,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '03',
              title: 'Fuzzy Mamdani (Inisiasi)',
              subtitle: 'Evaluasi Handover Factor (HF) terhadap ambang batas dinamis',
              icon: Icons.psychology_outlined,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '04',
              title: 'TOPSIS (Seleksi Target)',
              subtitle: 'Perangkingan kandidat terbaik dengan matriks bobot AHP',
              icon: Icons.sort_outlined,
              isLast: false,
            ),
            const _PipelineStepItem(
              stepNumber: '05',
              title: 'Stabilizer (Anti Ping-Pong)',
              subtitle: 'Dwell time 3.0 detik & hysteresis gain minimum >= 0.05',
              icon: Icons.shield_outlined,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineStepItem extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLast;

  const _PipelineStepItem({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left track: badge number + vertical connecting line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: context.borderColor,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Right content: title, subtitle, icon
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textSecondaryColor,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 16, color: context.textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu Utama Grid (Desain Monokrom Bersih, Tanpa Lingkaran Warna-Warni)
class _MainMenuGridSection extends StatelessWidget {
  const _MainMenuGridSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.32,
          children: [
            _MenuActionCard(
              title: 'Monitor Simulasi',
              subtitle: 'Cockpit RF & keputusan live',
              icon: Icons.sensors,
              onTap: () => context.go('/monitor'),
            ),
            _MenuActionCard(
              title: 'Konfigurasi',
              subtitle: 'Ambang Fuzzy & bobot TOPSIS',
              icon: Icons.tune,
              onTap: () => context.go('/settings'),
            ),
            _MenuActionCard(
              title: 'Hasil Evaluasi',
              subtitle: 'Metrik handover & performa',
              icon: Icons.analytics_outlined,
              onTap: () => context.go('/results'),
            ),
            _MenuActionCard(
              title: 'Log Keputusan',
              subtitle: 'Audit trail keputusan lengkap',
              icon: Icons.list_alt,
              onTap: () => context.push('/logs'),
            ),
            _MenuActionCard(
              title: 'Lompat Simulasi',
              subtitle: 'Pilih +10s, +50s, +100s, +500s',
              icon: Icons.fast_forward_outlined,
              onTap: () => _showJumpSheet(context),
            ),
            _MenuActionCard(
              title: 'Reset Skenario',
              subtitle: 'Mulai ulang dari awal',
              icon: Icons.restart_alt,
              onTap: () => context.read<SimulationController>().reset(),
            ),
          ],
        ),
      ],
    );
  }

  void _showJumpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lompat Simulasi Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih durasi lompatan untuk memajukan skenario mobilitas secara instan:',
                style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sec in [1, 10, 50, 100, 250, 500])
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        side: BorderSide(color: context.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<SimulationController>().fastForward(sec);
                      },
                      child: Text(
                        '+$sec Detik',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _MenuActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: context.textPrimaryColor, size: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
