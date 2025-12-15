// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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
  final Random _rng = Random();
  
  late List<int> _digits;
  late List<bool> _spinning;
  final List<Timer> _timers = [];
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _digits = List.generate(
      _digitCount,
      (i) => int.tryParse(widget.initialLosnummer[i]) ?? _rng.nextInt(10),
    );
    _spinning = List<bool>.filled(_digitCount, true);
    _startWalzen();
  }

  void _startWalzen() {
    final baseMs = widget.totalDuration.inMilliseconds;
    for (int i = 0; i < _digitCount; i++) {
      final stopAfter = Duration(milliseconds: (baseMs * (0.6 + i * 0.1)).toInt());
      final timer = Timer.periodic(const Duration(milliseconds: 60), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _digits[i] = (_digits[i] + 1) % 10);
      });
      _timers.add(timer);
      
      Future.delayed(stopAfter, () {
        if (!mounted) return;
        timer.cancel();
        setState(() {
          _digits[i] = _rng.nextInt(10);
          _spinning[i] = false;
        });
        _checkFinished();
      });
    }
  }

  void _checkFinished() {
    if (_finished || _spinning.any((e) => e)) return;
    _finished = true;
    final result = _digits.join();
    Future.delayed(widget.holdDuration, () {
      if (!mounted) return;
      widget.onDone(result);
      Navigator.of(context).pop();
    });
  }

  void _stopAll() {
    for (int i = 0; i < _digitCount; i++) {
      if (_spinning[i]) {
        _timers[i].cancel();
        _digits[i] = _rng.nextInt(10);
        _spinning[i] = false;
      }
    }
    setState(() {});
    _checkFinished();
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
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔴 Roter Kopfbereich – originalnah
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Text(
                  'GLÜCKSSPIRALE   •   SPIEL 77   •   SUPER 6   •   SUPERZAHL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 🔢 Losnummernfeld mit Klammern
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Zahlenreihe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_digitCount, (i) {
                        final isSuperzahl = i == 6;
                        return Container(
                          width: 32,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: isSuperzahl ? Colors.red : Colors.black,
                              width: isSuperzahl ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_digits[i]}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSuperzahl ? Colors.red : Colors.black,
                            ),
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Klammern und Beschriftungen
                    // Glücksspirale Klammer (alle 7 Zahlen)
                    Row(
                      children: [
                        Container(
                          width: 224, // 7*32 = 224
                          height: 20,
                          child: Stack(
                            children: [
                              // Obere Klammer
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.black, width: 1),
                                      left: BorderSide(color: Colors.black, width: 1),
                                      right: BorderSide(color: Colors.black, width: 1),
                                    ),
                                  ),
                                ),
                              ),
                              // Beschriftung
                              const Positioned(
                                top: 2,
                                left: 90,
                                child: Text(
                                  'Glücksspirale',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Super6 Klammer (letzte 6 Zahlen)
                    Row(
                      children: [
                        const SizedBox(width: 32), // Erste Zahl überspringen
                        Container(
                          width: 192, // 6*32 = 192
                          height: 20,
                          child: Stack(
                            children: [
                              // Obere Klammer
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.black, width: 1),
                                      left: BorderSide(color: Colors.black, width: 1),
                                      right: BorderSide(color: Colors.black, width: 1),
                                    ),
                                  ),
                                ),
                              ),
                              // Beschriftung
                              const Positioned(
                                top: 2,
                                left: 75,
                                child: Text(
                                  'Super 6',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Spiel77 Klammer (alle 7 Zahlen von unten)
                    Row(
                      children: [
                        Container(
                          width: 224,
                          height: 20,
                          child: Stack(
                            children: [
                              // Untere Klammer
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black, width: 1),
                                      left: BorderSide(color: Colors.black, width: 1),
                                      right: BorderSide(color: Colors.black, width: 1),
                                    ),
                                  ),
                                ),
                              ),
                              // Beschriftung
                              const Positioned(
                                bottom: 2,
                                left: 95,
                                child: Text(
                                  'Spiel77',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Superzahl Klammer (7. Ziffer)
                    Row(
                      children: [
                        const SizedBox(width: 192), // Erste 6 Zahlen überspringen
                        Container(
                          width: 32,
                          height: 20,
                          child: Stack(
                            children: [
                              // Rote Klammer
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              // Beschriftung
                              const Positioned(
                                bottom: -15,
                                left: 2,
                                child: Text(
                                  'Superzahl',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // STOPP Button
              SizedBox(
                width: 120,
                height: 36,
                child: ElevatedButton(
                  onPressed: _stopAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'STOPP',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
