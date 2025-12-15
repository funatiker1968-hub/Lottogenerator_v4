import 'package:flutter/material.dart';
import 'app_flow.dart';

// DEBUG: Statistik-Testlauf (nur Konsole)
import 'services/statistics/statistics_debug_runner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Statistik einmal durchlaufen lassen (DB / Analysen / Generatoren)
  // ignore: avoid_print
  StatisticsDebugRunner().runAll();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lottogenerator V4',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppFlow(),
      debugShowCheckedModeBanner: false,
    );
  }
}
