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

    // 2. Intro
    if (!_introDone) {
      return const IntroSlotScreen(
        key: const ValueKey('intro'),
      );
    }

    // 3. Home
    return const HomeScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Prüfe regelmäßig ob Intro fertig ist
    if (_accepted && !_introDone) {
      // Starte Timer der prüft (alle 500ms)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _accepted && !_introDone) {
          // Hier könnten wir einen Callback vom IntroScreen haben
          // Aber da wir keinen haben, machen wir es nach Zeit
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && !_introDone) {
              setState(() => _introDone = true);
            }
          });
        }
      });
    }
  }
}
