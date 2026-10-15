import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';

/// Screen 2 — Home Dashboard sesuai PRD v1.0/v2.0
///
/// Berisi:
/// - Status Card (status aktif simulasi & jaringan)
/// - Alur Simulator (5 langkah proses keputusan)
/// - Menu Utama Grid (6 kartu aksi cepat)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        key: PageStorageKey('home_scroll_key'),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SimulationStatusHeroCard(),
            SizedBox(height: 20),
            _SimulatorWorkflowSection(),
            SizedBox(height: 20),
            _MainMenuGridSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Kartu Hero Status Terakhir (Status Card PRD Section 1)
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
        gradient: LinearGradient(
          colors: isUnavailable
              ? [const Color(0xFF8B0000), AppTheme.errorRed]
              : [AppTheme.deepNavy, AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isRunning ? const Color(0xFF69F0AE) : Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRunning ? 'SIMULASI AKTIF' : 'TERJEDA / STANDBY',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Langkah $stepIndex',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isUnavailable
                ? 'Sinyal $activeNetworkId hilang (out of range). Beralih ke jaringan alternatif.'
                : (isRecommended
                    ? 'Sistem Fuzzy-TOPSIS mendeteksi kandidat dengan kualitas lebih optimal.'
                    : 'Jaringan aktif masih mencukupi kebutuhan kelas trafik saat ini.'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                icon: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  size: 18,
                  color: AppTheme.darkNavy,
                ),
                label: Text(
                  isRunning ? 'Jeda' : 'Lanjutkan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNavy,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.fast_forward, size: 16, color: Colors.white),
                label: const Text(
                  '+100s',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
                  ),
                ),
                onPressed: () => context.read<SimulationController>().fastForward(100),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.speed, size: 16, color: Colors.white),
                label: const Text(
                  'Monitor',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
                  ),
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

/// Alur Simulator 5 Langkah (PRD Section 2)
class _SimulatorWorkflowSection extends StatelessWidget {
  const _SimulatorWorkflowSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Alur Simulator Vertical Handover',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _WorkflowStepCard(
                stepNumber: '1',
                title: 'Generator',
                subtitle: 'Mobilitas & RF',
                icon: Icons.cell_tower,
                color: Color(0xFFE3F2FD),
                accentColor: AppTheme.primaryBlue,
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '2',
                title: 'QoS Factor',
                subtitle: 'Rate, Delay, BER',
                icon: Icons.calculate,
                color: Color(0xFFE8F5E9),
                accentColor: AppTheme.successGreen,
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '3',
                title: 'Fuzzy FIS',
                subtitle: 'HF > Threshold',
                icon: Icons.psychology,
                color: Color(0xFFFFF3E0),
                accentColor: AppTheme.warningOrange,
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '4',
                title: 'TOPSIS',
                subtitle: 'Seleksi Terbaik',
                icon: Icons.leaderboard,
                color: Color(0xFFF3E5F5),
                accentColor: Color(0xFF7B1FA2),
              ),
              _WorkflowArrow(),
              _WorkflowStepCard(
                stepNumber: '5',
                title: 'Stabilizer',
                subtitle: 'Anti Ping-Pong',
                icon: Icons.verified_user,
                color: Color(0xFFE0F2F1),
                accentColor: Color(0xFF00796B),
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
  final Color color;
  final Color accentColor;

  const _WorkflowStepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
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
      child: Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textTertiary),
    );
  }
}

/// Menu Utama Grid (PRD Section 3)
class _MainMenuGridSection extends StatelessWidget {
  const _MainMenuGridSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Menu Utama',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _MenuActionCard(
              title: 'Monitor Simulasi',
              subtitle: 'Cockpit RF & keputusan live',
              icon: Icons.sensors,
              color: AppTheme.primaryBlue,
              onTap: () => context.go('/monitor'),
            ),
            _MenuActionCard(
              title: 'Konfigurasi',
              subtitle: 'Ambang Fuzzy & bobot TOPSIS',
              icon: Icons.tune,
              color: AppTheme.warningOrange,
              onTap: () => context.go('/settings'),
            ),
            _MenuActionCard(
              title: 'Hasil Evaluasi',
              subtitle: 'Metrik handover & performa',
              icon: Icons.analytics,
              color: const Color(0xFF7B1FA2),
              onTap: () => context.go('/results'),
            ),
            _MenuActionCard(
              title: 'Log Keputusan',
              subtitle: 'Audit trail keputusan lengkap',
              icon: Icons.receipt_long,
              color: AppTheme.successGreen,
              onTap: () => context.push('/logs'),
            ),
            _MenuActionCard(
              title: 'Lompat Simulasi',
              subtitle: 'Pilih +10s, +50s, +100s, +500s',
              icon: Icons.fast_forward,
              color: const Color(0xFF00796B),
              onTap: () => _showJumpSheet(context),
            ),
            _MenuActionCard(
              title: 'Reset Skenario',
              subtitle: 'Mulai ulang dari awal',
              icon: Icons.restart_alt,
              color: AppTheme.errorRed,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.fast_forward, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    'Lompat Simulasi Cepat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih durasi lompatan untuk memajukan skenario mobilitas secara instan:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final sec in [1, 10, 50, 100, 250, 500])
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: Text('+$sec Detik'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightBlueBg,
                        foregroundColor: AppTheme.primaryBlue,
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.primaryBlue, width: 0.8),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<SimulationController>().fastForward(sec);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Simulasi melompat maju $sec langkah.'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
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
  final Color color;
  final VoidCallback onTap;

  const _MenuActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
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
