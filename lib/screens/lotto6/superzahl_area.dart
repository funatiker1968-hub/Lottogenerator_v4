import 'dart:math';
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// SUPERZAHL-BEREICH MIT LOSNUMMER + WALZENBUTTON
/// Dieser Bereich ist vollständig eigenständig und NICHT von Lotto6Screen abhängig.
/// Wird einfach im Hauptscreen eingebunden.
/// ---------------------------------------------------------------------------

class SuperzahlArea extends StatefulWidget {
  final double height;

  const SuperzahlArea({super.key, required this.height});

  @override
  State<SuperzahlArea> createState() => _SuperzahlAreaState();
}

class _SuperzahlAreaState extends State<SuperzahlArea> {
  final Random _rng = Random();

  late List<int> _digits; // 7-stellige Losnummer
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _digits = List.generate(7, (_) => _rng.nextInt(10));
  }

  void _generateNew() {
    if (_rolling) return;

    setState(() {
      _digits = List.generate(7, (_) => _rng.nextInt(10));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFFFD0D0), // Hellrot – wie gewünscht
      child: Row(
        children: [
          // Titel
          const Text(
            "Superzahl / Losnummer",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const Spacer(),

          // 7-stellige Nummer
          Row(
            children: List.generate(
              7,
              (i) => Container(
                width: 24,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Center(
                  child: Text(
                    _digits[i].toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Button: neue Nummer
          ElevatedButton(
            onPressed: _generateNew,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              "Neu",
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
