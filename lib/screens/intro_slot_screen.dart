import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class IntroSlotScreen extends StatefulWidget {
  const IntroSlotScreen({super.key});

  @override
  State<IntroSlotScreen> createState() => _IntroSlotScreenState();
}

class _IntroSlotScreenState extends State<IntroSlotScreen> {
  final List<String> chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split('');
  final Random rnd = Random();

  Timer? _timer;
  List<String> reel = List.filled(36, '?');
  bool _finished = false;
  int _ticks = 0;

  final String finalText = 
      "ZAHLENGENERATOR FÜR 6AUS49 UND EUROJACKPOT BY FUNATIKER";

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 56), (_) {
      if (!mounted) return;
      
      setState(() {
        _ticks++;

        if (_ticks < 30) {
          reel = List.generate(36, (_) => chars[rnd.nextInt(chars.length)]);
        } else if (_ticks < 70) {
          for (int i = 0; i < reel.length; i++) {
            if (rnd.nextDouble() < (_ticks - 30) / 40) {
              reel[i] = finalText[i];
            } else {
              reel[i] = chars[rnd.nextInt(chars.length)];
            }
          }
        } else if (!_finished) {
          for (int i = 0; i < reel.length; i++) {
            reel[i] = finalText[i];
          }
          _finished = true;
          _timer?.cancel();
          
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              // Intro ist fertig, AppFlow wird navigieren
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(33, 33, 33, 204), // RGBO statt withOpacity
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.yellow, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(255, 235, 59, 76), // RGBO statt withOpacity
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: reel
                    .map(
                      (c) => Container(
                        width: 22,
                        height: 48,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(20, 20, 20, 1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade700),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 128), // RGBO statt withOpacity
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          c,
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Column(
              children: [
                if (_finished)
                  const Text(
                    "App wird gestartet...",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                if (!_finished)
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        _finished = true;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text(
                      "Intro überspringen",
                      style: TextStyle(fontSize: 14),
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
