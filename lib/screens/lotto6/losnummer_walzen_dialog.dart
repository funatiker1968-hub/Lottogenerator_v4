import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Dialog mit 7 Walzen für die Losnummer.
/// Dreht die Ziffern für [totalDuration] oder bis der Nutzer STOPP drückt.
/// Am Ende wird die finale Nummer über [onDone] zurückgegeben.
class LosnummerWalzenDialog extends StatefulWidget {
  final String initialLosnummer;
  final Duration totalDuration;
  final ValueChanged<String> onDone;

  const LosnummerWalzenDialog({
    super.key,
    required this.initialLosnummer,
    required this.totalDuration,
    required this.onDone,
  });

  @override
  State<LosnummerWalzenDialog> createState() => _LosnummerWalzenDialogState();
}

class _LosnummerWalzenDialogState extends State<LosnummerWalzenDialog> {
  static const int _digitCount = 7;
  static const Duration _tick = Duration(milliseconds: 70);

  final Random _rng = Random();
  late List<int> _digits;
  Timer? _timer;
  late DateTime _endTime;
  bool _requestedStop = false;

  @override
  void initState() {
    super.initState();
    _digits = _parseInitial(widget.initialLosnummer);
    _startSpin();
  }

  List<int> _parseInitial(String value) {
    final cleaned = value.padLeft(_digitCount, '0');
    return cleaned
        .split('')
        .map((c) => int.tryParse(c) ?? _rng.nextInt(10))
        .toList();
  }

  void _startSpin() {
    _endTime = DateTime.now().add(widget.totalDuration);
    _timer = Timer.periodic(_tick, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      final now = DateTime.now();
      if (_requestedStop || now.isAfter(_endTime)) {
        t.cancel();
        _finish();
        return;
      }

      setState(() {
        // Jede Walze bekommt eine neue Zufallsziffer
        for (var i = 0; i < _digits.length; i++) {
          _digits[i] = _rng.nextInt(10);
        }
      });
    });
  }

  void _finish() {
    final result = _digits.join();
    widget.onDone(result);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onStopPressed() {
    setState(() {
      _requestedStop = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF303030),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFA000), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Losnummer-Walzen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_digitCount, (index) {
                  final d = _digits[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 32,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFF7043),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 140,
                height: 44,
                child: ElevatedButton(
                  onPressed: _onStopPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('STOPP'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
