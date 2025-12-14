import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class IntroSlotScreen extends StatefulWidget {
  // FIX: Entweder Parameter entfernen oder final Variable initialisieren
  // Da AppFlow den Screen direkt instanziiert, brauchen wir keinen Callback
  const IntroSlotScreen({super.key});

  @override
  State<IntroSlotScreen> createState() => _IntroSlotScreenState();
}

class _IntroSlotScreenState extends State<IntroSlotScreen> {
  final List<String> chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split('');
  final Random rnd = Random();

  Timer? _timer;
  List<String> reel = List.filled(18, '?');
  bool _finished = false;
  int _ticks = 0;

  final String finalText = 
      "ZAHLENGENERATOR FÜR 6AUS49 UND EUROJACKPOT BY FUNATIKER";

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _ticks++;

        if (_ticks < 40) {
          reel = List.generate(18, (_) => chars[rnd.nextInt(chars.length)]);
        } else if (_ticks < 100) {
          for (int i = 0; i < reel.length; i++) {
            if (rnd.nextDouble() < (_ticks - 40) / 60) {
              reel[i] = finalText[i];
            } else {
              reel[i] = chars[rnd.nextInt(chars.length)];
            }
          }
        } else if (!_finished) {
          reel = finalText.substring(0, 18).split('');
          _finished = true;
          _timer?.cancel();

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // AppFlow steuert die Navigation, also nichts tun
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reel
              .map(
                (c) => Container(
                  width: 20,
                  height: 40,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(33, 33, 33, 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
