import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/disclaimer_screen.dart';
import 'screens/intro_slot_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lotto_6aus49_screen.dart';
import 'screens/eurojackpot_screen.dart';
import 'historie_page.dart';
import 'statistik_page.dart';
import 'lotto_import_page.dart';

void main() {
  runApp(const LottoGeneratorApp());
}

class LottoGeneratorApp extends StatefulWidget {
  const LottoGeneratorApp({super.key});

  @override
  State<LottoGeneratorApp> createState() => _LottoGeneratorAppState();
}

class _LottoGeneratorAppState extends State<LottoGeneratorApp> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Lottogenerator",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      initialRoute: "/",

      routes: {
        "/": (_) => _accepted
            ? const IntroSlotScreen()          // NACH Disclaimer Intro starten
            : DisclaimerScreen(
                onAccept: () {
                  setState(() => _accepted = true);
                },
                onDecline: () => SystemNavigator.pop(),
              ),

        "/home":     (_) => const HomeScreen(),
        "/lotto":    (_) => const Lotto6aus49Screen(),
        "/euro":     (_) => const EurojackpotScreen(),
        "/historie": (_) => const HistoriePage(),
        "/statistik":(_) => const StatistikPage(),
        "/import":   (_) => const LottoImportPage(),
      },
    );
  }
}
