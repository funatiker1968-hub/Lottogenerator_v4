import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Vollbild-Walzenbildschirm für die 7-stellige Losnummer.
/// Startet automatisch, läuft ca. 3,5 Sekunden und kann über STOP sofort beendet werden.
/// Ergebnis wird als List<int> an den Aufrufer zurückgegeben.
class WalzenScreen extends StatefulWidget {
  final List<int> initialDigits;

  const WalzenScreen({
    super.key,
    required this.initialDigits,
  });

  @override
  State<WalzenScreen> createState() => _WalzenScreenState();
}

class _WalzenScreenState extends State<WalzenScreen> {
  final Random _rng = Random();

  late List<int> _currentDigits;
  late List<int> _targetDigits;
  late List<bool> _stoppedPerReel;

  bool _allStopped = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDigits = List<int>.from(widget.initialDigits);
    if (_currentDigits.length != 7) {
      _currentDigits = List<int>.filled(7, 0);
    }
    _targetDigits = List.generate(7, (_) => _rng.nextInt(10));
    _stoppedPerReel = List<bool>.filled(7, false);
    _startAnimation();
  }

  void _startAnimation() {
    const totalDuration = Duration(milliseconds: 3500);
    final startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      final elapsed = DateTime.now().difference(startTime);

      if (elapsed >= totalDuration || _allStopped) {
        _stopAll();
        return;
      }

      setState(() {
        for (int i = 0; i < 7; i++) {
          if (_stoppedPerReel[i]) continue;
          _currentDigits[i] = (_currentDigits[i] + 1) % 10;
        }
      });
    });
  }

  void _stopAll() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      for (int i = 0; i < 7; i++) {
        _currentDigits[i] = _targetDigits[i];
        _stoppedPerReel[i] = true;
      }
      _allStopped = true;
    });

    // kurze Pause, dann Pop mit Ergebnis
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.of(context).pop<List<int>>(
        List<int>.from(_currentDigits),
      );
    });
  }

  void _onStopPressed() {
    if (_allStopped) return;
    _allStopped = true;
    _stopAll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: Container(
            width: size.width * 0.9,
            height: size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Losnummer-Walzen',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(7, (i) {
                    return Container(
                      width: 40,
                      height: 70,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${_currentDigits[i]}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _onStopPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'STOPP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
