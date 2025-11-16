import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class EurojackpotScreen extends StatefulWidget {
  const EurojackpotScreen({super.key});

  @override
  State<EurojackpotScreen> createState() => _EurojackpotScreenState();
}

class _EurojackpotScreenState extends State<EurojackpotScreen> {
  static const int tipCount = 8;
  static const int mainMaxNumber = 50;      // 1–50
  static const int mainNumbersPerTip = 5;   // 5 Zahlen pro Tipp
  static const int euroMaxNumber = 12;      // 1–12
  static const int euroNumbersPerTip = 2;   // 2 Eurozahlen pro Tipp

  final Random _random = Random();

  /// Hauptzahlen (5 aus 50) – pro Tipp eine Liste mit 50 Booleans
  final List<List<bool>> _mainSelected =
      List.generate(tipCount, (_) => List<bool>.filled(mainMaxNumber, false));
  final List<List<int>> _mainGenerated =
      List.generate(tipCount, (_) => <int>[]);

  /// Eurozahlen (2 aus 12) – pro Tipp eine Liste mit 12 Booleans
  final List<List<bool>> _euroSelected =
      List.generate(tipCount, (_) => List<bool>.filled(euroMaxNumber, false));
  final List<List<int>> _euroGenerated =
      List.generate(tipCount, (_) => <int>[]);

  /// Welcher Tipp ist gerade aktiv (0–7)
  int _currentTipIndex = 0;

  /// Lauflicht-Kreuz für Hauptzahlen (1–50)
  int? _currentMainHighlight;

  /// Lauflicht-Kreuz für Eurozahlen (1–12)
  int? _currentEuroHighlight;

  /// Während Animation gesperrt
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _resetAllTips();
  }

  void _resetAllTips() {
    for (int t = 0; t < tipCount; t++) {
      for (int i = 0; i < mainMaxNumber; i++) {
        _mainSelected[t][i] = false;
      }
      for (int i = 0; i < euroMaxNumber; i++) {
        _euroSelected[t][i] = false;
      }
      _mainGenerated[t].clear();
      _euroGenerated[t].clear();
    }
    _currentTipIndex = 0;
    _currentMainHighlight = null;
    _currentEuroHighlight = null;
    _isGenerating = false;
  }

  void _clearTip(int tipIndex) {
    setState(() {
      for (int i = 0; i < mainMaxNumber; i++) {
        _mainSelected[tipIndex][i] = false;
      }
      for (int i = 0; i < euroMaxNumber; i++) {
        _euroSelected[tipIndex][i] = false;
      }
      _mainGenerated[tipIndex].clear();
      _euroGenerated[tipIndex].clear();

      if (_currentTipIndex == tipIndex) {
        _currentMainHighlight = null;
        _currentEuroHighlight = null;
      }
    });
  }

  void _clearAllTips() {
    setState(_resetAllTips);
  }

  /// Laufendes Kreuz über alle 50 Zahlen + Setzen der 5 Treffer
  Future<void> _runTipAnimation(int tipIndex) async {
    // Zufallszahlen bestimmen
    final Set<int> mainSet = <int>{};
    while (mainSet.length < mainNumbersPerTip) {
      mainSet.add(_random.nextInt(mainMaxNumber) + 1);
    }

    final Set<int> euroSet = <int>{};
    while (euroSet.length < euroNumbersPerTip) {
      euroSet.add(_random.nextInt(euroMaxNumber) + 1);
    }

    // Tipp leeren
    for (int i = 0; i < mainMaxNumber; i++) {
      _mainSelected[tipIndex][i] = false;
    }
    for (int i = 0; i < euroMaxNumber; i++) {
      _euroSelected[tipIndex][i] = false;
    }
    _mainGenerated[tipIndex] = <int>[];
    _euroGenerated[tipIndex] = <int>[];

    // Lauflicht über Hauptzahlen 1–50: Kreuz läuft, bleibt bei Treffern stehen
    for (int n = 1; n <= mainMaxNumber; n++) {
      if (!mounted) return;

      final bool isTarget = mainSet.contains(n);
      setState(() {
        _currentMainHighlight = n;

        if (isTarget) {
          _mainSelected[tipIndex][n - 1] = true;
          if (!_mainGenerated[tipIndex].contains(n)) {
            _mainGenerated[tipIndex].add(n);
            _mainGenerated[tipIndex].sort();
          }
        }
      });

      // Treffer etwas länger „angeleuchtet“
      await Future.delayed(Duration(milliseconds: isTarget ? 120 : 40));
    }

    if (!mounted) return;
    setState(() {
      _currentMainHighlight = null;
    });

    // Lauflicht über Eurozahlen 1–12
    for (int n = 1; n <= euroMaxNumber; n++) {
      if (!mounted) return;

      final bool isTarget = euroSet.contains(n);
      setState(() {
        _currentEuroHighlight = n;

        if (isTarget) {
          _euroSelected[tipIndex][n - 1] = true;
          if (!_euroGenerated[tipIndex].contains(n)) {
            _euroGenerated[tipIndex].add(n);
            _euroGenerated[tipIndex].sort();
          }
        }
      });

      await Future.delayed(Duration(milliseconds: isTarget ? 140 : 50));
    }

    if (!mounted) return;
    setState(() {
      _currentEuroHighlight = null;
    });
  }

  Future<void> _generateSingleTip(int tipIndex) async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _currentTipIndex = tipIndex;
    });

    await _runTipAnimation(tipIndex);

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
    });
  }

  Future<void> _generateAllTips() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    for (int t = 0; t < tipCount; t++) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = t;
      });
      await _runTipAnimation(t);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _currentTipIndex = 0;
      _currentMainHighlight = null;
      _currentEuroHighlight = null;
    });
  }

  /// Manuelles Anklicken im 5-aus-50-Feld
  void _onMainNumberTap(int number) {
    if (_isGenerating) return;
    final int tipIndex = _currentTipIndex;
    final int idx = number - 1;

    setState(() {
      final bool selected = _mainSelected[tipIndex][idx];

      if (selected) {
        _mainSelected[tipIndex][idx] = false;
        _mainGenerated[tipIndex].remove(number);
      } else {
        if (_mainGenerated[tipIndex].length >= mainNumbersPerTip) {
          return;
        }
        _mainSelected[tipIndex][idx] = true;
        _mainGenerated[tipIndex].add(number);
        _mainGenerated[tipIndex].sort();
      }
    });
  }

  /// Manuelles Anklicken im Eurozahlenfeld 2-aus-12
  void _onEuroNumberTap(int number) {
    if (_isGenerating) return;
    final int tipIndex = _currentTipIndex;
    final int idx = number - 1;

    setState(() {
      final bool selected = _euroSelected[tipIndex][idx];

      if (selected) {
        _euroSelected[tipIndex][idx] = false;
        _euroGenerated[tipIndex].remove(number);
      } else {
        if (_euroGenerated[tipIndex].length >= euroNumbersPerTip) {
          return;
        }
        _euroSelected[tipIndex][idx] = true;
        _euroGenerated[tipIndex].add(number);
        _euroGenerated[tipIndex].sort();
      }
    });
  }

  /// Tipp-Auswahlleiste (Tipp 1–8)
  Widget _buildTipSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List<Widget>.generate(tipCount, (int index) {
        final bool isActive = index == _currentTipIndex;
        final bool hasNumbers =
            _mainGenerated[index].isNotEmpty || _euroGenerated[index].isNotEmpty;

        return ChoiceChip(
          label: Text('Tipp ${index + 1}'),
          selected: isActive,
          onSelected: _isGenerating
              ? null
              : (_) {
                  setState(() {
                    _currentTipIndex = index;
                  });
                },
          avatar: hasNumbers
              ? const Icon(Icons.check, size: 16)
              : const Icon(Icons.circle_outlined, size: 14),
        );
      }),
    );
  }

  /// 5-aus-50 Feld (optisch wie Schein: 5 Reihen x 10 Spalten)
  Widget _buildMainGrid(Orientation orientation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10, // 5 Reihen x 10 Spalten = 50 Zahlen
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: mainMaxNumber,
        itemBuilder: (BuildContext context, int index) {
          final int number = index + 1;
          final bool isSelected = _mainSelected[_currentTipIndex][index];
          final bool isHighlight = _currentMainHighlight == number;

          Color bgColor = Colors.yellow.shade100;
          Color borderColor = Colors.red.shade700;
          Color textColor = Colors.black;
          String text = number.toString();

          // Laufendes Kreuz
          if (isHighlight && !isSelected) {
            bgColor = Colors.orange;
            textColor = Colors.white;
            text = '✗';
          } else if (isSelected) {
            bgColor = Colors.red.shade600;
            textColor = Colors.white;
            text = '✗';
          }

          return GestureDetector(
            onTap: _isGenerating ? null : () => _onMainNumberTap(number),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Eurozahlen-Feld 2-aus-12 (2 Reihen x 6 Spalten)
  Widget _buildEuroGrid(Orientation orientation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: euroMaxNumber,
        itemBuilder: (BuildContext context, int index) {
          final int number = index + 1;
          final bool isSelected = _euroSelected[_currentTipIndex][index];
          final bool isHighlight = _currentEuroHighlight == number;

          Color bgColor = Colors.yellow.shade100;
          Color borderColor = Colors.red.shade700;
          Color textColor = Colors.black;
          String text = number.toString();

          if (isHighlight && !isSelected) {
            bgColor = Colors.orange;
            textColor = Colors.white;
            text = '✗';
          } else if (isSelected) {
            bgColor = Colors.red.shade600;
            textColor = Colors.white;
            text = '✗';
          }

          return GestureDetector(
            onTap: _isGenerating ? null : () => _onEuroNumberTap(number),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Buttons: aktueller Tipp / alle Tipps
  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isGenerating ? null : () => _generateSingleTip(_currentTipIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.casino),
                label: const Text('Tipp generieren'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isGenerating ? null : () => _clearTip(_currentTipIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.delete),
                label: const Text('Tipp löschen'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generateAllTips,
                icon: const Icon(Icons.auto_mode),
                label: const Text('Alle generieren'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _clearAllTips,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Alle löschen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Übersicht über alle Tipps unten
  Widget _buildTipSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List<Widget>.generate(tipCount, (int index) {
          final main = _mainGenerated[index];
          final euro = _euroGenerated[index];

          if (main.isEmpty && euro.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'Tipp ${index + 1}: –',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipp ${index + 1}: ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      ...main.map(
                        (n) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            n.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      ...euro.map(
                        (n) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'E$n',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Eurojackpot'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTipSelector(),
                const SizedBox(height: 12),
                const Text(
                  'Tippfeld 5 aus 50',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildMainGrid(orientation),
                const SizedBox(height: 16),
                const Text(
                  'Eurozahlen 2 aus 12',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildEuroGrid(orientation),
                const SizedBox(height: 16),
                _buildControls(),
                const SizedBox(height: 16),
                _buildTipSummary(),
              ],
            ),
          ),
        );
      },
    );
  }
}
