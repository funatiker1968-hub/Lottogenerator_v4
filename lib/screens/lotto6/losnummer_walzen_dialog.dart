import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Dialog mit animierten Walzen für die 7-stellige Losnummer.
///
/// - Jede Ziffer dreht wie eine Walze.
/// - Walzen starten gleichzeitig, stoppen aber nacheinander (links -> rechts).
/// - Drehung wird langsamer, bevor sie stehen bleibt.
/// - Nach Stopp bleiben die Zahlen noch [holdDuration] sichtbar,
///   dann wird [onDone] aufgerufen und der Dialog geschlossen.
class LosnummerWalzenDialog extends StatefulWidget {
  final String initialLosnummer;
  final Duration totalDuration;
  final Duration holdDuration;
  final ValueChanged<String> onDone;

  const LosnummerWalzenDialog({
    super.key,
    required this.initialLosnummer,
    required this.totalDuration,
    required this.holdDuration,
    required this.onDone,
  });

  @override
  State<LosnummerWalzenDialog> createState() => _LosnummerWalzenDialogState();
}

class _LosnummerWalzenDialogState extends State<LosnummerWalzenDialog> {
  static const int _digitCount = 7;
  static final Random _rng = Random();

  late List<int> _digits;
  late List<bool> _spinning;
  final List<Timer> _timers = [];

  bool _stoppedManually = false;
  bool _doneScheduled = false;

  @override
  void initState() {
    super.initState();
    _digits = List<int>.generate(
      _digitCount,
      (i) => int.tryParse(
            widget.initialLosnummer[i],
          ) ??
          _rng.nextInt(10),
    );
    _spinning = List<bool>.filled(_digitCount, true);
    _startAnimation();
  }

  void _startAnimation() {
    _timers.clear();
    final baseMs = widget.totalDuration.inMilliseconds;

    for (int i = 0; i < _digitCount; i++) {
      // jede Walze hat etwas längere Laufzeit als die vorherige
      final double factor = 0.5 + (i / (_digitCount - 1)) * 0.7;
      final int runMs = (baseMs * factor).toInt();
      final DateTime stopAt = DateTime.now().add(Duration(milliseconds: runMs));

      int tickMs = 45; // startet relativ schnell

      final timer = Timer.periodic(
        Duration(milliseconds: tickMs),
        (t) {
          if (!mounted) {
            t.cancel();
            return;
          }

          if (_stoppedManually || DateTime.now().isAfter(stopAt)) {
            // Walze auslaufen lassen: ein letztes Mal eine Zufallsziffer setzen
            setState(() {
              _digits[i] = _rng.nextInt(10);
              _spinning[i] = false;
            });
            t.cancel();
            _checkAllFinished();
          } else {
            // leichtes "Abbremsen": Tick-Intervall langsam vergrößern
            tickMs = (tickMs * 1.03).clamp(45, 140).toInt();
            t.cancel();
            _timers.remove(t);
            final newTimer = Timer.periodic(
              Duration(milliseconds: tickMs),
              (nt) {
                if (!mounted) {
                  nt.cancel();
                  return;
                }
                if (_stoppedManually || DateTime.now().isAfter(stopAt)) {
                  setState(() {
                    _digits[i] = _rng.nextInt(10);
                    _spinning[i] = false;
                  });
                  nt.cancel();
                  _checkAllFinished();
                } else {
                  setState(() {
                    _digits[i] = (_digits[i] + 1) % 10;
                  });
                }
              },
            );
            _timers.add(newTimer);
          }
        },
      );

      _timers.add(timer);
    }
  }

  void _checkAllFinished() {
    if (_doneScheduled) return;
    if (_spinning.any((s) => s)) return;

    _doneScheduled = true;
    final result = _digits.join();

    // 5 Sekunden stehen lassen, dann schließen
    Timer(widget.holdDuration, () {
      if (!mounted) return;
      widget.onDone(result);
      Navigator.of(context).pop();
    });
  }

  void _onStopPressed() {
    if (_stoppedManually) return;
    _stoppedManually = true;

    setState(() {
      for (int i = 0; i < _digitCount; i++) {
        if (_spinning[i]) {
          _digits[i] = _rng.nextInt(10);
          _spinning[i] = false;
        }
      }
    });
    _checkAllFinished();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Losnummer-Walzen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0E0),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: const Text(
                    'Glücksspirale   |   Spiel 77   |   SUPER 6   |   Superzahl',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_digitCount, (i) {
                    return Container(
                      width: 32,
                      height: 46,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _spinning[i]
                              ? Colors.orange
                              : Colors.red.shade700,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${_digits[i]}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _spinning[i]
                                ? Colors.black
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 140,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _onStopPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'STOPP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nach dem Stopp bleibt die\nLosnummer kurz stehen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
