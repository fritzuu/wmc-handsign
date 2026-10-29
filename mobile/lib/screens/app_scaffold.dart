import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/simulation/simulation.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Shell utama aplikasi yang membungkus seluruh navigasi tab dalam
/// kontainer mobile viewport terpusat (Centered Mobile Viewport, maxWidth: 440px)
/// dengan dukungan Light & Dark Mode.
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.desktopCanvasColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
                blurRadius: 32,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WMC Simulator',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'Vertical Handover Decision System',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: context.borderColor),
              ),
              actions: [
                IconButton(
                  tooltip: isDark ? 'Beralih ke mode terang' : 'Beralih ke mode gelap',
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 19,
                    color: context.textPrimaryColor,
                  ),
                  onPressed: () {
                    context.read<ThemeController>().toggleTheme(context);
                  },
                ),
                const SizedBox(width: 2),
                const _LiveStatusBadge(),
                const SizedBox(width: 14),
              ],
            ),
            body: navigationShell,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).navigationBarTheme.backgroundColor ?? context.cardColor,
                border: Border(
                  top: BorderSide(color: context.borderColor, width: 1.0),
                ),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                height: 64,
                onDestinationSelected: (index) {
                  final controller = context.read<SimulationController>();
                  if (index == 2) {
                    controller.setDataSourceMode(SimulationDataSourceMode.liveHardwareProbe);
                  } else if (controller.isLiveMode) {
                    controller.setDataSourceMode(SimulationDataSourceMode.simulationHetNet);
                  }
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: 'Simulasi',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sensors_outlined),
                    selectedIcon: Icon(Icons.sensors),
                    label: 'Realtime',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics),
                    label: 'Hasil',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune),
                    label: 'Pengaturan',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge indikator status eksekusi simulasi di pojok kanan AppBar.
class _LiveStatusBadge extends StatelessWidget {
  const _LiveStatusBadge();

  @override
  Widget build(BuildContext context) {
    final isRunning = context.select<SimulationController, bool>((c) => c.isRunning);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.chipBorderRadius),
          border: Border.all(color: context.borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isRunning ? AppTheme.successGreen : context.textTertiaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isRunning ? 'LIVE' : 'STANDBY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
