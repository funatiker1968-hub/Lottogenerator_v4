import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'core_colors.dart';

/// --------------------------------------------------------------------------
/// Superzahl-Bereich: breites Laufband 0–9 + Kugel
/// Variante A (wie dein altes blaues Band, nur jetzt gelb)
/// --------------------------------------------------------------------------
class SuperzahlArea extends StatefulWidget {
  final double height;
  const SuperzahlArea({super.key, required this.height});

  @override
  State<SuperzahlArea> createState() => _SuperzahlAreaState();
}

class _SuperzahlAreaState extends State<SuperzahlArea> {
  final Random _rng = Random();

  int _activeIndex = 0;     // Highlight im Laufband
  int _ballNumber = 0;      // Zahl in der Kugel
  bool _running = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_running) return;

    setState(() => _running = true);

    final int target = _rng.nextInt(10);

    int stepDelay = 60;
    int steps = 0;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: stepDelay), (t) {
      if (!mounted) return;

      steps++;
      _activeIndex = (_activeIndex + 1) % 10;
      _ballNumber = _activeIndex;
      setState(() {});

      // leicht langsamer werden
      if (steps % 20 == 0 && stepDelay < 220) {
        stepDelay += 40;
        t.cancel();
        _timer = Timer.periodic(Duration(milliseconds: stepDelay), (t2) {
          if (!mounted) return;
          _activeIndex = (_activeIndex + 1) % 10;
          _ballNumber = _activeIndex;
          setState(() {});
        });
      }

      // wenn langsam genug → auf Zielzahl auslaufen
      if (stepDelay >= 220 && _activeIndex == target) {
        t.cancel();
        _timer?.cancel();

        // kleines Einrasten
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          setState(() => _running = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final bandHeight = h * 0.55;
    final ballSize = h * 0.70;

    return Container(
      color: kLottoYellow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // ----------------- Laufband 0–9 -----------------
          Expanded(
            child: Container(
              height: bandHeight,
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (i) {
                  final bool active = i == _activeIndex;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: active
                            ? Colors.orangeAccent
                            : Colors.yellow.shade50,
                        border: Border.all(
                          color: active ? Colors.red : Colors.black87,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$i",
                          style: TextStyle(
                            fontSize: active ? 18 : 16,
                            fontWeight:
                                active ? FontWeight.bold : FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ----------------- Kugel -----------------
          Container(
            width: ballSize,
            height: ballSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFFFDE7),
                  Color(0xFFFFF176),
                ],
                center: Alignment(-0.3, -0.3),
                radius: 0.9,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(3, 4),
                  color: Colors.black26,
                )
              ],
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 140),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                child: Text("$_ballNumber"),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ----------------- Start-Button -----------------
          ElevatedButton(
            onPressed: _running ? null : _start,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _running ? Colors.grey.shade400 : Colors.greenAccent,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(_running ? "Läuft…" : "Start"),
          ),
        ],
      ),
    );
  }
}
