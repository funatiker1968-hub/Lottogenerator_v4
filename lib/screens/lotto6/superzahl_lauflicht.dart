import 'package:flutter/material.dart';

/// ===========================================================================
/// SUPERZAHL-LAUFLICHT 0–9
/// ===========================================================================
/// Eigenschaften:
/// - 10 Felder (0–9)
/// - Hintergrund dunkelblau
/// - Text weiß
/// - Highlight helleres Blau
/// - 4 Durchgänge: schnell → mittel → langsam → sehr langsam
/// - Stoppt auf Zieldigit
/// - Danach blinkt finale Ziffer 3×
/// - Callback für Synchronisierung mit Kugelanimation
/// ===========================================================================

class SuperzahlLauflicht extends StatefulWidget {
  final double height;
  final Function(int)? onStep;          // Wird bei jedem Digit-Schritt ausgelöst
  final Function(int)? onFinalDigit;    // Wird ausgelöst, wenn Ziel erreicht ist

  const SuperzahlLauflicht({
    super.key,
    required this.height,
    this.onStep,
    this.onFinalDigit,
  });

  @override
  State<SuperzahlLauflicht> createState() => _SuperzahlLauflichtState();
}

class _SuperzahlLauflichtState extends State<SuperzahlLauflicht> {
  int _highlight = -1;
  bool _running = false;

  /// Farben
  final Color baseColor = const Color(0xFF003A80);   // Dunkelblau
  final Color hiColor = const Color(0xFF0066CC);     // Hellblau
  final Color borderColor = const Color(0xFF1A1A1A);

  /// --------------------------------------------------------------
  /// Startet die komplette 4-Stufen-Animation
  /// --------------------------------------------------------------
  Future<void> startRun(int targetDigit) async {
    if (_running) return;
    _running = true;

    List<int> delays = [
      80,    // Durchgang 1: schnell
      110,   // Durchgang 2
      150,   // Durchgang 3
      220,   // Durchgang 4 (stoppt hier auf Ziel)
    ];

    // 4 Durchgänge, letzter stoppt auf targetDigit
    for (int round = 1; round <= 4; round++) {
      for (int i = 0; i < 10; i++) {
        setState(() => _highlight = i);
        widget.onStep?.call(i);

        // Letzter Durchgang: Stopp bei Zieldigit
        if (round == 4 && i == targetDigit) {
          widget.onFinalDigit?.call(i);
          await _blinkFinal(i);
          _running = false;
          return;
        }

        await Future.delayed(Duration(milliseconds: delays[round - 1]));
      }
    }
  }

  /// --------------------------------------------------------------
  /// Finale Blink-Sequenz (3×)
  /// --------------------------------------------------------------
  Future<void> _blinkFinal(int digit) async {
    for (int j = 0; j < 3; j++) {
      setState(() => _highlight = -1);
      await Future.delayed(const Duration(milliseconds: 180));
      setState(() => _highlight = digit);
      await Future.delayed(const Duration(milliseconds: 180));
    }
  }

  @override
  Widget build(BuildContext context) {
    double cellW = widget.height * 0.75;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (digit) {
          bool isHi = digit == _highlight;

          return Container(
            width: cellW,
            height: widget.height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isHi ? hiColor : baseColor,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                digit.toString(),
                style: TextStyle(
                  fontSize: widget.height * 0.55,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
