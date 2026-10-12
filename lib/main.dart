import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/mobility/mobility.dart';
import 'widgets/mobility_monitor_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MobilityController(
            initialMode: MobilitySpeedMode.manualStatic,
            initialManualSpeed: 1.4,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'WMC Handover Recommender',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D1B2A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WMC Vertical Handover'),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            MobilityMonitorCard(),
          ],
        ),
      ),
    );
  }
}
