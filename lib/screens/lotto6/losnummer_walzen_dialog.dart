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
      final stopAfter =
          Duration(milliseconds: (baseMs * (0.6 + i * 0.1)).toInt());

      final timer = Timer.periodic(const Duration(milliseconds: 60), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }

        setState(() {
          _digits[i] = (_digits[i] + 1) % 10;
        });
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
    if (_finished) return;
    if (_spinning.any((e) => e)) return;

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
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Losnummer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_digitCount, (i) {
                  final isSuperzahl = i == 6;
                  return Container(
                    width: 32,
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSuperzahl ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_digits[i]}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isSuperzahl ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 6),
              const Text(
                'Superzahl',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: 140,
                height: 40,
                child: ElevatedButton(
                  onPressed: _stopAll,
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
            ],
          ),
        ),
      ),
    );
  }
}
