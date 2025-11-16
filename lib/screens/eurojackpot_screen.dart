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
  static const int maxMainNumber = 50; // 5 aus 50
  static const int mainNumbersPerTip = 5;
  static const int maxEuroNumber = 12; // 2 aus 12
  static const int euroNumbersPerTip = 2;

  final Random _random = Random();

  /// Hauptzahlen: pro Tipp 50 Felder (1–50), true = angekreuzt
  final List<List<bool>> _selectedMain = List.generate(
    tipCount,
    (_) => List.filled(maxMainNumber, false),
  );

  /// Eurozahlen: pro Tipp 12 Felder (1–12), true = angekreuzt
  final List<List<bool>> _selectedEuro = List.generate(
    tipCount,
    (_) => List.filled(maxEuroNumber, false),
  );

  /// Gemerkte Tippzahlen (nur zur Anzeige, eigentlich aus selected ableitbar)
  final List<List<int>> _generatedMain =
      List.generate(tipCount, (_) => <int>[]);
  final List<List<int>> _generatedEuro =
      List.generate(tipCount, (_) => <int>[]);

  /// Simple globales Animations-Flag: keine Parallel-Generierung
  bool _isAnimating = false;

  /// Lauflicht für Hauptzahlen
  int? _currentMainHighlightTip;
  int? _currentMainHighlightNumber;

  /// Lauflicht für Eurozahlen
  int? _currentEuroHighlightTip;
  int? _currentEuroHighlightNumber;

  /// Eine Tipp-Reihe generieren (Haupt + Euro) mit Lauflicht
  Future<void> _generateTip(int tipIndex) async {
    if (_isAnimating) return;

    // Bereits manuell gesetzte Hauptzahlen einsammeln (Favoriten)
    final List<int> currentMain = [];
    for (int i = 0; i < maxMainNumber; i++) {
      if (_selectedMain[tipIndex][i]) currentMain.add(i + 1);
    }

    // Bereits gesetzte Eurozahlen einsammeln
    final List<int> currentEuro = [];
    for (int i = 0; i < maxEuroNumber; i++) {
      if (_selectedEuro[tipIndex][i]) currentEuro.add(i + 1);
    }

    final int mainNeeded = mainNumbersPerTip - currentMain.length;
    final int euroNeeded = euroNumbersPerTip - currentEuro.length;

    if (mainNeeded <= 0 && euroNeeded <= 0) {
      // Alles schon voll – nichts zu tun
      return;
    }

    // Kandidaten Hauptzahlen
    final List<int> availableMain = [
      for (int n = 1; n <= maxMainNumber; n++)
        if (!currentMain.contains(n)) n,
    ];
    availableMain.shuffle(_random);
    final List<int> newMain = availableMain
        .take(mainNeeded.clamp(0, availableMain.length))
        .toList();
    final List<int> finalMain = [...currentMain, ...newMain]..sort();

    // Kandidaten Eurozahlen
    final List<int> availableEuro = [
      for (int n = 1; n <= maxEuroNumber; n++)
        if (!currentEuro.contains(n)) n,
    ];
    availableEuro.shuffle(_random);
    final List<int> newEuro = availableEuro
        .take(euroNeeded.clamp(0, availableEuro.length))
        .toList();
    final List<int> finalEuro = [...currentEuro, ...newEuro]..sort();

    setState(() {
      _isAnimating = true;
      _generatedMain[tipIndex] = finalMain;
      _generatedEuro[tipIndex] = finalEuro;

      // Nur Favoriten anfangs lassen – generierte kommen im Lauflicht dazu
      for (int i = 0; i < maxMainNumber; i++) {
        _selectedMain[tipIndex][i] = currentMain.contains(i + 1);
      }
      for (int i = 0; i < maxEuroNumber; i++) {
        _selectedEuro[tipIndex][i] = currentEuro.contains(i + 1);
      }
    });

    // Lauflicht über Hauptfeld: 2 Runden über 1–50
    for (int pass = 0; pass < 2; pass++) {
      for (int n = 1; n <= maxMainNumber; n++) {
        if (!mounted) return;
        setState(() {
          _currentMainHighlightTip = tipIndex;
          _currentMainHighlightNumber = n;
          if (finalMain.contains(n)) {
            _selectedMain[tipIndex][n - 1] = true; // Kreuz bleibt
          }
        });
        await Future.delayed(const Duration(milliseconds: 28));
      }
    }

    // Lauflicht Hauptzahlen ausblenden
    if (!mounted) return;
    setState(() {
      _currentMainHighlightTip = null;
      _currentMainHighlightNumber = null;
    });

    // Lauflicht über Eurofeld: 2 Runden über 1–12
    for (int pass = 0; pass < 2; pass++) {
      for (int n = 1; n <= maxEuroNumber; n++) {
        if (!mounted) return;
        setState(() {
          _currentEuroHighlightTip = tipIndex;
          _currentEuroHighlightNumber = n;
          if (finalEuro.contains(n)) {
            _selectedEuro[tipIndex][n - 1] = true;
          }
        });
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }

    if (!mounted) return;
    setState(() {
      _currentEuroHighlightTip = null;
      _currentEuroHighlightNumber = null;
      _isAnimating = false;
    });
  }

  /// Einzelnen Tipp komplett löschen
  void _clearTip(int tipIndex) {
    if (_isAnimating) return;

    setState(() {
      for (int i = 0; i < maxMainNumber; i++) {
        _selectedMain[tipIndex][i] = false;
      }
      for (int i = 0; i < maxEuroNumber; i++) {
        _selectedEuro[tipIndex][i] = false;
      }
      _generatedMain[tipIndex].clear();
      _generatedEuro[tipIndex].clear();

      if (_currentMainHighlightTip == tipIndex) {
        _currentMainHighlightTip = null;
        _currentMainHighlightNumber = null;
      }
      if (_currentEuroHighlightTip == tipIndex) {
        _currentEuroHighlightTip = null;
        _currentEuroHighlightNumber = null;
      }
    });
  }

  /// Alle Tipps nacheinander generieren (mit Animation)
  Future<void> _generateAll() async {
    if (_isAnimating) return;
    for (int t = 0; t < tipCount; t++) {
      await _generateTip(t);
    }
  }

  /// Alle Tipps löschen
  void _clearAll() {
    if (_isAnimating) return;
    for (int t = 0; t < tipCount; t++) {
      _clearTip(t);
    }
  }

  /// Hauptzahl manuell toggeln (Favoriten / generierte anpassbar)
  void _toggleMain(int tipIndex, int idx) {
    if (_isAnimating) return;
    setState(() {
      final bool currently = _selectedMain[tipIndex][idx];
      if (currently) {
        _selectedMain[tipIndex][idx] = false;
      } else {
        int count = 0;
        for (int i = 0; i < maxMainNumber; i++) {
          if (_selectedMain[tipIndex][i]) count++;
        }
        if (count >= mainNumbersPerTip) {
          // Nicht mehr als 5 pro Tipp
          return;
        }
        _selectedMain[tipIndex][idx] = true;
      }

      _generatedMain[tipIndex] = [
        for (int i = 0; i < maxMainNumber; i++)
          if (_selectedMain[tipIndex][i]) i + 1
      ];
    });
  }

  /// Eurozahl manuell toggeln
  void _toggleEuro(int tipIndex, int idx) {
    if (_isAnimating) return;
    setState(() {
      final bool currently = _selectedEuro[tipIndex][idx];
      if (currently) {
        _selectedEuro[tipIndex][idx] = false;
      } else {
        int count = 0;
        for (int i = 0; i < maxEuroNumber; i++) {
          if (_selectedEuro[tipIndex][i]) count++;
        }
        if (count >= euroNumbersPerTip) {
          // Nicht mehr als 2 pro Tipp
          return;
        }
        _selectedEuro[tipIndex][idx] = true;
      }

      _generatedEuro[tipIndex] = [
        for (int i = 0; i < maxEuroNumber; i++)
          if (_selectedEuro[tipIndex][i]) i + 1
      ];
    });
  }

  /// Hauptzahlen-Gitter: 5 aus 50 als 5x10 (Lottoschein-Stil)
  Widget _buildMainGrid(int tipIndex) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown.shade400),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: maxMainNumber,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10, // 5 Reihen à 10 Zahlen
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final int number = index + 1;
          final bool isSelected = _selectedMain[tipIndex][index];
          final bool isHighlight = _currentMainHighlightTip == tipIndex &&
              _currentMainHighlightNumber == number;

          Color bgColor;
          Color textColor = Colors.black;

          if (isHighlight) {
            bgColor = Colors.orange;
            textColor = Colors.white;
          } else if (isSelected) {
            bgColor = Colors.blue.shade700;
            textColor = Colors.white;
          } else {
            bgColor = Colors.white;
          }

          return GestureDetector(
            onTap: () => _toggleMain(tipIndex, index),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.red.shade700, width: 0.8),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 10,
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

  /// Eurozahlen-Gitter: 2 aus 12 als 2x6
  Widget _buildEuroGrid(int tipIndex) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade400),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: maxEuroNumber,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, // 2 Reihen à 6 Zahlen
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final int number = index + 1;
          final bool isSelected = _selectedEuro[tipIndex][index];
          final bool isHighlight = _currentEuroHighlightTip == tipIndex &&
              _currentEuroHighlightNumber == number;

          Color bgColor;
          Color textColor = Colors.black;

          if (isHighlight) {
            bgColor = Colors.orange;
            textColor = Colors.white;
          } else if (isSelected) {
            bgColor = Colors.green.shade700;
            textColor = Colors.white;
          } else {
            bgColor = Colors.white;
          }

          return GestureDetector(
            onTap: () => _toggleEuro(tipIndex, index),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.blue.shade700, width: 0.8),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 10,
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

  /// Eine komplette Tipp-Kachel im Schein-Look
  Widget _buildTip(int tipIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.yellow.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade700, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipp ${tipIndex + 1}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildMainGrid(tipIndex),
          const SizedBox(height: 4),
          const Text(
            'Eurozahlen',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildEuroGrid(tipIndex),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAnimating ? null : () => _generateTip(tipIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'GENERIEREN',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAnimating ? null : () => _clearTip(tipIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'LÖSCHEN',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 600;

          Widget tipsLayout;
          if (isWide) {
            // Quer: 2 Spalten mit je 4 Tipps (2x4)
            tipsLayout = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (int i = 0; i < 4; i++) _buildTip(i),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      for (int i = 4; i < tipCount; i++) _buildTip(i),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Hochkant: 8 Tipps untereinander
            tipsLayout = Column(
              children: [
                for (int i = 0; i < tipCount; i++) _buildTip(i),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Eurojackpot – 8 Tippfelder (5 aus 50 + 2 aus 12)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                tipsLayout,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnimating ? null : _generateAll,
                        icon: const Icon(Icons.auto_mode, size: 18),
                        label: const Text(
                          'ALLE GENERIEREN',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnimating ? null : _clearAll,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text(
                          'ALLES LÖSCHEN',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
