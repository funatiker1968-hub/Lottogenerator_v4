// EurojackpotScreen v1 – erstellt am 16.11.2025, 16:00 CET

import 'dart:math';
import 'package:flutter/material.dart';

class EurojackpotScreen extends StatefulWidget {
  const EurojackpotScreen({super.key});

  @override
  State<EurojackpotScreen> createState() => _EurojackpotScreenState();
}

class _EurojackpotScreenState extends State<EurojackpotScreen> {
  static const int _maxMain = 50;     // 1–50
  static const int _mainCount = 5;    // 5 Zahlen
  static const int _maxEuro = 12;     // 1–12
  static const int _euroCount = 2;    // 2 Eurozahlen

  final List<bool> _mainSelected = List<bool>.filled(_maxMain, false);
  final List<bool> _euroSelected = List<bool>.filled(_maxEuro, false);

  final Random _random = Random();

  bool get _isComplete =>
      _mainSelected.where((e) => e).length == _mainCount &&
      _euroSelected.where((e) => e).length == _euroCount;

  List<int> _currentMainNumbers() {
    final result = <int>[];
    for (int i = 0; i < _maxMain; i++) {
      if (_mainSelected[i]) {
        result.add(i + 1);
      }
    }
    result.sort();
    return result;
  }

  List<int> _currentEuroNumbers() {
    final result = <int>[];
    for (int i = 0; i < _maxEuro; i++) {
      if (_euroSelected[i]) {
        result.add(i + 1);
      }
    }
    result.sort();
    return result;
  }

  void _toggleMain(int index) {
    setState(() {
      final bool currently = _mainSelected[index];
      if (currently) {
        _mainSelected[index] = false;
      } else {
        final int count = _mainSelected.where((e) => e).length;
        if (count < _mainCount) {
          _mainSelected[index] = true;
        }
      }
    });
  }

  void _toggleEuro(int index) {
    setState(() {
      final bool currently = _euroSelected[index];
      if (currently) {
        _euroSelected[index] = false;
      } else {
        final int count = _euroSelected.where((e) => e).length;
        if (count < _euroCount) {
          _euroSelected[index] = true;
        }
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (int i = 0; i < _maxMain; i++) {
        _mainSelected[i] = false;
      }
      for (int i = 0; i < _maxEuro; i++) {
        _euroSelected[i] = false;
      }
    });
  }

  void _generateRandom() {
    setState(() {
      // Hauptzahlen auffüllen
      final currentMain = _currentMainNumbers().toSet();
      final List<int> poolMain =
          List<int>.generate(_maxMain, (i) => i + 1)..removeWhere(currentMain.contains);
      while (currentMain.length + (currentMain.length < _mainCount ? 1 : 0) <= _mainCount &&
          currentMain.length < _mainCount &&
          poolMain.isNotEmpty) {
        final pick = poolMain.removeAt(_random.nextInt(poolMain.length));
        currentMain.add(pick);
      }

      // Auf Selektion anwenden
      for (int i = 0; i < _maxMain; i++) {
        _mainSelected[i] = currentMain.contains(i + 1);
      }

      // Eurozahlen auffüllen
      final currentEuro = _currentEuroNumbers().toSet();
      final List<int> poolEuro =
          List<int>.generate(_maxEuro, (i) => i + 1)..removeWhere(currentEuro.contains);
      while (currentEuro.length + (currentEuro.length < _euroCount ? 1 : 0) <= _euroCount &&
          currentEuro.length < _euroCount &&
          poolEuro.isNotEmpty) {
        final pick = poolEuro.removeAt(_random.nextInt(poolEuro.length));
        currentEuro.add(pick);
      }

      for (int i = 0; i < _maxEuro; i++) {
        _euroSelected[i] = currentEuro.contains(i + 1);
      }
    });
  }

  Widget _buildNumberCell({
    required int number,
    required bool selected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? activeColor.withValues(alpha: 0.8) : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hauptzahlen (5 aus 50)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _maxMain,
            itemBuilder: (context, index) {
              final int number = index + 1;
              return _buildNumberCell(
                number: number,
                selected: _mainSelected[index],
                onTap: () => _toggleMain(index),
                activeColor: Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEuroGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Eurozahlen (2 aus 12)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _maxEuro,
            itemBuilder: (context, index) {
              final int number = index + 1;
              return _buildNumberCell(
                number: number,
                selected: _euroSelected[index],
                onTap: () => _toggleEuro(index),
                activeColor: Colors.orange,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final main = _currentMainNumbers();
    final euro = _currentEuroNumbers();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dein Tipp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            main.isEmpty
                ? 'Hauptzahlen: –'
                : 'Hauptzahlen: ${main.join(', ')}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            euro.isEmpty
                ? 'Eurozahlen: –'
                : 'Eurozahlen: ${euro.join(', ')}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _isComplete
                ? 'Tipp vollständig.'
                : 'Bitte wähle $_mainCount Hauptzahlen und $_euroCount Eurozahlen.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _isComplete ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eurojackpot'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Wähle deine Zahlen oder lass sie zufällig generieren.\n'
                'Offizielles Schema: 5 aus 50 + 2 aus 12.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildMainGrid(),
              const SizedBox(height: 12),
              _buildEuroGrid(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateRandom,
                      icon: const Icon(Icons.auto_mode),
                      label: const Text('Zufallstipp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete),
                      label: const Text('Alles löschen'),
                    ),
                  ),
                ],
              ),
              _buildSummary(),
            ],
          ),
        ),
      ),
    );
  }
}
