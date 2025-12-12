import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SlotIntroScreen extends StatefulWidget {
  const SlotIntroScreen({super.key});

  @override
  State<SlotIntroScreen> createState() => _SlotIntroScreenState();
}

class _SlotIntroScreenState extends State<SlotIntroScreen> {
  final List<String> chars = [
    'A','B','C','D','E','F','G','H','I','J',
    'K','L','M','N','O','P','Q','R','S','T',
    'U','V','W','X','Y','Z','0','1','2','3',
    '4','5','6','7','8','9'
  ];

  late Timer _timer;
  List<String> row1 = [];
  List<String> row2 = [];
  List<String> row3 = [];
  int tick = 0;

  bool finished = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    final rnd = Random();
    row1 = List.generate(16, (_) => chars[rnd.nextInt(chars.length)]);
    row2 = List.generate(16, (_) => chars[rnd.nextInt(chars.length)]);
    row3 = List.generate(16, (_) => chars[rnd.nextInt(chars.length)]);

    _timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      setState(() {
        tick++;

        if (tick <= 40) {
          row1.shuffle();
        }
        if (tick <= 70) {
          row2.shuffle();
        }
        if (tick <= 100) {
          row3.shuffle();
        }

        if (tick == 110) {
          _showFinalMessage();
        }
      });
    });
  }

  void _showFinalMessage() {
    setState(() {
      finished = true;
      row1 = "LOTT OGEN ERAT OR".split('');
      row2 = "FÜR 6AUS49".padRight(16).split('');
      row3 = "UND EUROJACKPOT".padRight(16).split('');
    });
    _timer.cancel();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  Widget _buildRow(List<String> chars) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: chars.map((c) {
          return Container(
            width: 20,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Text(
              c,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRow(row1),
            _buildRow(row2),
            _buildRow(row3),
            const SizedBox(height: 20),
            if (finished)
              const Text(
                "by Funatiker",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
