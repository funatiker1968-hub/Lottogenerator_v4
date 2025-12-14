import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class IntroSlotScreen extends StatefulWidget {
  final VoidCallback? onIntroComplete;
  const IntroSlotScreen({super.key, this.onIntroComplete});
  const IntroSlotScreen({super.key});

  @override
  State<IntroSlotScreen> createState() => _IntroSlotScreenState();
}

class _IntroSlotScreenState extends State<IntroSlotScreen> {
  final List<String> chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split('');
  final Random rnd = Random();

  late Timer _timer;
  List<String> reel = List.filled(180, '?');

  bool _finished = false;
  int _ticks = 0;

  final String finalText =
      "LOTTOZAHLENGENERATOR FÜR LOTTO 6AUS49 UND EUROJACKPOT BY FUNATIKER";

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _ticks++;

        if (_ticks < 40) {
          // Phase 1: völliger Buchstabensalat
          reel = List.generate(18, (_) => chars[rnd.nextInt(chars.length)]);
        } else if (_ticks < 100) {
          // Phase 2: Reel langsam stabilisieren
          for (int i = 0; i < reel.length; i++) {
            if (rnd.nextDouble() < (_ticks - 40) / 60) {
              reel[i] = finalText[i];
            } else {
              reel[i] = chars[rnd.nextInt(chars.length)];
            }
          }
        } else {
          // Phase 3: Finaltext steht komplett
          reel = finalText.substring(0, 20).split('');
          _finished = true;
          _timer.cancel();
          if (widget.onIntroComplete != null) {
            widget.onIntroComplete!();
          }
          // Automatisch zum nächsten Screen wechseln
          Timer(const Duration(seconds: 2), () {
            if (mounted) Navigator.pushReplacementNamed(context, "/");
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
          if (widget.onIntroComplete != null) {
            widget.onIntroComplete!();
          }
          // Automatisch zum nächsten Screen wechseln
          Timer(const Duration(seconds: 2), () {
            if (mounted) Navigator.pushReplacementNamed(context, "/");
          });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Walzenfeld
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
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
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c,
                          style: theme.textTheme.titleLarge?.copyWith(
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
            const SizedBox(height: 40),

            if (_finished)
              Column(
                children: [
                  Text(
                    "Lottozahlengenerator",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "für Lotto 6aus49 und Eurojackpot",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.yellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "by Funatiker",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
