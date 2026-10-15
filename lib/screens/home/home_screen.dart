import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';

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
            SizedBox(height: 22),
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
    final activeNetworkId = context.select<SimulationController, String>((c) => c.activeNetworkId);
    final isUnavailable = context.select<SimulationController, bool>((c) => c.isActiveNetworkUnavailable);
    final isRecommended = context.select<SimulationController, bool>((c) => c.isHandoverRecommended);
    final targetId = context.select<SimulationController, String?>((c) => c.recommendedTargetId);

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
                ? 'Koneksi Terputus: $activeNetworkId'
                : (isRecommended ? 'Rekomendasi: Pindah ke $targetId' : 'Koneksi Stabil: $activeNetworkId'),
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
                ? 'Sinyal $activeNetworkId terputus. Sistem menyiapkan perpindahan darurat.'
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

/// Alur Simulator 5 Langkah (Desain Monokrom Bersih dengan Padding Presisi)
class _SimulatorWorkflowSection extends StatelessWidget {
  const _SimulatorWorkflowSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alur Simulator Vertical Handover',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: const [
              _WorkflowStepCard(
                stepNumber: '01',
                title: 'Generator',
                subtitle: 'Mobilitas & RF',
                icon: Icons.cell_tower,
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '02',
                title: 'QoS Factor',
                subtitle: 'Rate, Delay, BER',
                icon: Icons.calculate_outlined,
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '03',
                title: 'Fuzzy FIS',
                subtitle: 'HF > Threshold',
                icon: Icons.psychology_outlined,
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '04',
                title: 'TOPSIS',
                subtitle: 'Seleksi Terbaik',
                icon: Icons.sort_outlined,
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '05',
                title: 'Stabilizer',
                subtitle: 'Anti Ping-Pong',
                icon: Icons.shield_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;

  const _WorkflowStepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepNumber,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textTertiary,
                ),
              ),
              Icon(icon, color: AppTheme.textPrimary, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowArrow extends StatelessWidget {
  const _WorkflowArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textTertiary),
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
        const Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
            color: AppTheme.textPrimary,
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
      backgroundColor: Colors.white,
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
              const Text(
                'Lompat Simulasi Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih durasi lompatan untuk memajukan skenario mobilitas secara instan:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                        side: const BorderSide(color: AppTheme.dividerColor),
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
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
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
        side: const BorderSide(color: AppTheme.dividerColor, width: 1.0),
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
              Icon(icon, color: AppTheme.textPrimary, size: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
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
