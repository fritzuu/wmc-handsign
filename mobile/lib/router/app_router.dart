import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/app_scaffold.dart';
import '../screens/home/home_screen.dart';
import '../screens/logs/decision_log_screen.dart';
import '../screens/monitor/monitor_screen.dart';
import '../screens/realtime/realtime_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/settings/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Konfigurasi routing deklaratif aplikasi menggunakan go_router.
///
/// Menggunakan StatefulShellRoute.indexedStack untuk menjamin state,
/// scroll offset, dan timer simulasi pada setiap tab tetap aktif saat navigasi.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Beranda
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 2: Simulasi (Live Monitor)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/monitor',
              builder: (context, state) => const MonitorScreen(),
            ),
          ],
        ),

        // Tab 3: Realtime Telemetri Hardware Fisik
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/realtime',
              builder: (context, state) => const RealtimeScreen(),
            ),
          ],
        ),

        // Tab 4: Hasil & Metrik Evaluasi
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/results',
              builder: (context, state) => const ResultsScreen(),
            ),
          ],
        ),

        // Tab 5: Pengaturan & Konfigurasi
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Rute Mandiri: Log Keputusan
    GoRoute(
      path: '/logs',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DecisionLogScreen(),
    ),
  ],
);
