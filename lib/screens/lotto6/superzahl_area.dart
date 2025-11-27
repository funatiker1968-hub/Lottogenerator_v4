import 'dart:async';
import 'package:flutter/material.dart';
import 'core_colors.dart';

/// --------------------------------------------------------------------------
/// Superzahl-Bereich: Lauflicht 0–9 + Kugel mit Slot-Walzenbewegung
/// --------------------------------------------------------------------------
class SuperzahlArea extends StatefulWidget {
  final double height;
  const SuperzahlArea({super.key, required this.height});

  @override
  State<SuperzahlArea> createState() => _SuperzahlAreaState();
}

class _SuperzahlAreaState extends State<SuperzahlArea> {
  int _current = 0;              // für Lauflicht
  int _ballNumber = 0;           // angezeigte Kugelziffer
  bool _running = false;
  Timer? _timer;

  double _ballShift = 0;         // Verschiebung für saubere Animation

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Start
  // ---------------------------------------------------------------
  void _start() {
    if (_running) return;

    setState(() => _running = true);

    int cycles = 0;
    int speed = 45;

    _timer = Timer.periodic(Duration(milliseconds: speed), (t) {
      if (!mounted) return;

      // Lauflicht + Kugel synchron
      _current = (_current + 1) % 10;
      _ballNumber = _current;

      // Kugel-Walze (leicht nach rechts / zurück)
      _ballShift += 0.28;
      if (_ballShift > 1.0) _ballShift = 0.0;

      setState(() {});

      // Langsamer werden
      cycles++;
      if (cycles % 30 == 0) {
        speed += 60; // wird langsamer
        t.cancel();
        _timer = Timer.periodic(Duration(milliseconds: speed), (t2) {
          if (!mounted) return;
          _current = (_current + 1) % 10;
          _ballNumber = _current;

          _ballShift += 0.28;
          if (_ballShift > 1.0) _ballShift = 0.0;

          setState(() {});
        });
      }

      // Ende nach 4 Zyklen
      if (speed > 350) {
        t.cancel();
        _timer?.cancel();

        // final leichte Einrastbewegung
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          setState(() => _ballShift = 0.0);
        });

        setState(() => _running = false);
      }
    });
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final h = widget.height;

    return Container(
      color: kLottoYellow,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ---------------- Lauflicht 0–9 ----------------
          Row(
            children: List.generate(10, (i) {
              final active = (i == _current);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: active ? Colors.orangeAccent : Colors.white,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  "$i",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.black : Colors.black87,
                  ),
                ),
              );
            }),
          ),

          // ---------------- Superzahl-Kugel ----------------
          Transform.translate(
            offset: Offset(_ballShift * 4.0, 0),
            child: Container(
              width: h * 0.55,
              height: h * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.shade200,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(2, 2),
                    color: Colors.black26,
                  )
                ],
                border: Border.all(color: Colors.red, width: 3),
              ),
              child: Center(
                child: Text(
                  "$_ballNumber",
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // ---------------- Start-Button ----------------
          ElevatedButton(
            onPressed: _running ? null : _start,
            style: ElevatedButton.styleFrom(
              backgroundColor: _running ? Colors.grey : Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(_running ? "Läuft…" : "Start"),
          ),
        ],
      ),
    );
  }
}
