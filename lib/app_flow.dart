import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/intro_slot_screen.dart';
import 'screens/disclaimer_screen.dart';

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  bool _accepted = false;
  bool _introDone = false;

  @override
  Widget build(BuildContext context) {
    // 1. Disclaimer
    if (!_accepted) {
      return DisclaimerScreen(
        onAccept: () {
          setState(() => _accepted = true);
        },
        onDecline: () {
          // App wird durch DisclaimerScreen beendet
        },
      );
    }

    // 2. Intro (mit Callback - WICHTIG: Intro startet die App)
    if (!_introDone) {
      return IntroSlotScreen(
        onComplete: () {
          // WICHTIG: Intro ist fertig, App kann starten
          if (mounted) {
            setState(() => _introDone = true);
          }
        },
      );
    }

    // 3. Home (APP WIRD HIER GESTARTET)
    return const HomeScreen();
  }
}
