import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/intro_slot_screen.dart';
// Disclaimer-Screen EXISTIERT bereits bei dir
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
          // App bleibt leer / beendet sich logisch
        },
      );
    }

    // 2. Intro
    if (!_introDone) {
      return IntroSlotScreen(
        key: const ValueKey('intro'),
      );
    }

    // 3. Home
    return const HomeScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Intro automatisch beenden nach kurzer Zeit
    if (_accepted && !_introDone) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _introDone = true);
        }
      });
    }
  }
}
