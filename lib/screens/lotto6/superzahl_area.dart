import 'dart:async';
import 'package:flutter/material.dart';
import 'core_dimensions.dart';
import 'core_colors.dart';
import 'core_sounds.dart';

/// ===========================================================================
/// SUPERZAHL-AREA
/// Lauflicht 0–9 (4 Runden), synchron zur Kugel.
/// Finale Zahl blinkt 3×.
/// Stop-Sound: snake_exit.mp3
/// ===========================================================================

class SuperzahlArea extends StatefulWidget {
  final double height;
  const SuperzahlArea({super.key, required this.height});

  @override
  State<SuperzahlArea> createState() => _SuperzahlAreaState();
}

class _SuperzahlAreaState extends State<SuperzahlArea> {
  int _superNumber = 0;               // finale gezogene Zahl
  int _highlight = 0;                 // welcher Wert in der Leiste blinkt / läuft
  bool _running = false;              // blockiert Startbutton
  bool _blink = false;                // finale Blinkphase
  double _kugelShift = 0;             // Kugel-Animation (links ↔ rechts)
  double _kugelScale = 1.0;           // minimal größer in der Mitte

  @override
  void initState() {
    super.initState();
    LGSounds.preload();                // Sounds vorbereiten
  }

  // =========================================================================
  // START DES VIERERTAKTES
  // =========================================================================
  Future<void> _start() async {
    if (_running) return;

    setState(() => _running = true);
    LGSounds.stop();

    // neue Zufallszahl
    _superNumber = DateTime.now().millisecond % 10;

    // vier Durchläufe → schnell → mittel → langsam
    await _runPhase(60, loops: 12);    // Phase 1
    await _runPhase(90, loops: 10);    // Phase 2
    await _runPhase(130, loops: 10);   // Phase 3

    // Finalrunde → Stop auf Ziel
    await _runFinalPhase();

    // finale Blinkphase
    await _blinkFinal();

    setState(() => _running = false);
  }

  // =========================================================================
  // DURCHLAUF PHASE 1–3
  // =========================================================================
  Future<void> _runPhase(int delay, {required int loops}) async {
    for (int r = 0; r < loops; r++) {
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;

        setState(() {
          _highlight = i;
          _animateKugel(i);
        });

        // Sound → nur spin_fast bei Phase 1/2/3
        LGSounds.play('spin_fast.mp3');

        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  // =========================================================================
  // FINALE PHASE → exakt auf _superNumber stoppen
  // =========================================================================
  Future<void> _runFinalPhase() async {
    for (int i = 0; i <= _superNumber; i++) {
      if (!mounted) return;

      setState(() {
        _highlight = i;
        _animateKugel(i);
      });

      LGSounds.play('spin_slow.mp3');
      await Future.delayed(const Duration(milliseconds: 180));
    }

    // STOP-SOUND
    LGSounds.play('snake_exit.mp3');

    // Kugel 2× einwippen
    await _kugelWippen();
  }

  // =========================================================================
  // KUGEL-EFFEKT BEI JEDEM WERT
  // =========================================================================
  void _animateKugel(int i) {
    // leichte links→rechts Bewegung (3 Pixel / Zahl)
    _kugelShift = (i * 3).toDouble();

    // kleiner Skalierungspuls wenn genau die Mitte
    _kugelScale = (i == 5) ? 1.05 : 1.0;
  }

  // =========================================================================
  // KUGEL WIPPEN (2× links→rechts)
  // =========================================================================
  Future<void> _kugelWippen() async {
    for (int r = 0; r < 2; r++) {
      if (!mounted) return;

      setState(() => _kugelScale = 1.08);
      await Future.delayed(const Duration(milliseconds: 120));

      setState(() => _kugelScale = 0.96);
      await Future.delayed(const Duration(milliseconds: 120));

      setState(() => _kugelScale = 1.02);
      await Future.delayed(const Duration(milliseconds: 120));

      setState(() => _kugelScale = 1.0);
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  // =========================================================================
  // BLINKEN DER FINALEN ZAHL
  // =========================================================================
  Future<void> _blinkFinal() async {
    for (int b = 0; b < 3; b++) {
      setState(() => _blink = true);
      await Future.delayed(const Duration(milliseconds: 180));

      setState(() => _blink = false);
      await Future.delayed(const Duration(milliseconds: 180));
    }
  }

  // =========================================================================
  // WIDGET
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kLottoYellow,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Lauflicht (0–9)
          Expanded(
            flex: 6,
            child: _buildLauflicht(),
          ),

          // Kugel
          Expanded(
            flex: 5,
            child: _buildKugel(),
          ),

          // Button
          Expanded(
            flex: 4,
            child: _buildButton(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // LAUFLICHT 0–9
  // =========================================================================
  Widget _buildLauflicht() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(10, (i) {
        final bool active = (_highlight == i);

        // blink = nur für finale Zahl
        final bool isFinalBlink = (i == _superNumber && _blink);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 26,
          height: 32,
          decoration: BoxDecoration(
            color: isFinalBlink
                ? Colors.red
                : active
                    ? Colors.orange.shade300
                    : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            "$i",
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  active ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        );
      }),
    );
  }

  // =========================================================================
  // KUGEL MIT ROLLEFFEKT
  // =========================================================================
  Widget _buildKugel() {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..translate(_kugelShift)
          ..scale(_kugelScale),
        width: LottoDim.superBallSize.toDouble(),
        height: LottoDim.superBallSize.toDouble(),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white,
              Colors.yellow.shade300,
            ],
            center: Alignment.topLeft,
            radius: 0.95,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          "$_highlight",
          style: const TextStyle(
            fontSize: LottoDim.superBallFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BUTTON
  // =========================================================================
  Widget _buildButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _running ? null : _start,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _running ? Colors.grey.shade400 : Colors.greenAccent.shade400,
          foregroundColor: Colors.black,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Text(
          _running ? "läuft..." : "Start",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
