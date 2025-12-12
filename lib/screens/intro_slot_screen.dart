import 'dart:async';
import 'package:flutter/material.dart';

class IntroSlotScreen extends StatefulWidget {
  const IntroSlotScreen({super.key});

  @override
  State<IntroSlotScreen> createState() => _IntroSlotScreenState();
}

class _IntroSlotScreenState extends State<IntroSlotScreen> {
  String text = "";
  final String finalText =
      "Lottozahlengenerator für Lotto 6aus49 und Eurojackpot\nby Funatiker";

  @override
  void initState() {
    super.initState();

    // Kurze Wartezeit → Slot-Effekt
    Timer(const Duration(milliseconds: 300), _startAnimation);
  }

  void _startAnimation() async {
    // 2 Sekunden "Walzen-Effekt"
    for (int i = 0; i < 18; i++) {
      setState(() {
        text = _randomString(finalText.length);
      });
      await Future.delayed(const Duration(milliseconds: 80));
    }

    // Finale Schrift einblenden
    setState(() {
      text = finalText;
    });

    // 2 Sekunden warten → weiter zum HomeScreen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed("/home");
  }

  String _randomString(int length) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    return List.generate(
      length,
      (_) => chars[(chars.length * (DateTime.now(). microsecond % 1000) / 1000).floor()],
    ).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
