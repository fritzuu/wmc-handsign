import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/simulation/simulation.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.loadThemeMode();
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  final ThemeController? themeController;

  const MyApp({super.key, this.themeController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => themeController ?? (ThemeController()..loadThemeMode()),
        ),
        ChangeNotifierProvider(
          create: (_) => SimulationController(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeController>().themeMode;
          return MaterialApp.router(
            title: 'WMC Simulator',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
