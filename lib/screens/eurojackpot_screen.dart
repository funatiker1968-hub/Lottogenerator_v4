import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Eurojackpot – offizielles Farbschema & Layout
/// 5 aus 50 + 2 aus 12
/// 8 Tippfelder in fester 2x4 Matrix
/// Animationslauflicht optimiert
/// Farbsystem Eurojackpot-gerecht

// === Eurojackpot-Farben ===
const Color _ejGold = Color(0xFFC6A667);        // Highlight / Final
const Color _ejBronze = Color(0xFFA57C2B);      // Border
const Color _ejBeige = Color(0xFFEFE7D5);       // Normal Feld
const Color _ejLightBg = Color(0xFFF3E6C7);     // Tippkarten-Hintergrund
const Color _ejEuroArea = Color(0xFFF6F0E5);    // Eurozahlen-Bereich
const Color _ejChipGreen = Color(0xFF2E7D32);   // Ergebnis-Chips

class EurojackpotScreen extends StatefulWidget {
  const EurojackpotScreen({super.key});

  @override
  State<EurojackpotScreen> createState() => _EurojackpotScreenState();
}

class _EurojackpotScreenState extends State<EurojackpotScreen> {
  static const int tipCount = 8;
  static const int maxMainNumber = 50;
  static const int mainNumbersPerTip = 5;

  static const int maxEuroNumber = 12;
  static const int euroNumbersPerTip = 2;

  final Random _random = Random();

  // Auswahlstatus
  final List<List<bool>> _selectedMain =
      List.generate(tipCount, (_) => List.filled(maxMainNumber, false));
  final List<List<bool>> _selectedEuro =
      List.generate(tipCount, (_) => List.filled(maxEuroNumber, false));

  // Gemerkte Tippzahlen (für Ergebnis-Chips)
  final List<List<int>> _generatedMain =
      List.generate(tipCount, (_) => <int>[]);
  final List<List<int>> _generatedEuro =
      List.generate(tipCount, (_) => <int>[]);

  // Animation
  bool _isAnimating = false;
  int? _highlightMainTip;
  int? _highlightMainNumber;

  int? _highlightEuroTip;
  int? _highlightEuroNumber;

  // ============================================================
  //   Tipp generieren (Favoriten + Animation + Ergebnis)
  // ============================================================

  Future<void> _generateTip(int tipIndex) async {
    if (_isAnimating) return;

    // Favoriten einsammeln
    final List<int> currentMain = [
      for (int i = 0; i < maxMainNumber; i++)
        if (_selectedMain[tipIndex][i]) i + 1
    ];

    final List<int> currentEuro = [
      for (int i = 0; i < maxEuroNumber; i++)
        if (_selectedEuro[tipIndex][i]) i + 1
    ];

    final int mainNeed = mainNumbersPerTip - currentMain.length;
    final int euroNeed = euroNumbersPerTip - currentEuro.length;

    if (mainNeed <= 0 && euroNeed <= 0) return;

    // Kandidaten
    final List<int> availableMain = [
      for (int i = 1; i <= maxMainNumber; i++)
        if (!currentMain.contains(i)) i
    ];
    availableMain.shuffle(_random);
    final List<int> newMain = availableMain.take(mainNeed).toList();

    final List<int> finalMain = [...currentMain, ...newMain]..sort();

    final List<int> availableEuro = [
      for (int i = 1; i <= maxEuroNumber; i++)
        if (!currentEuro.contains(i)) i
    ];
    availableEuro.shuffle(_random);
    final List<int> newEuro = availableEuro.take(euroNeed).toList();

    final List<int> finalEuro = [...currentEuro, ...newEuro]..sort();

    setState(() {
      _isAnimating = true;

      // Nur Favoriten zunächst gesetzt lassen, generierte kommen in der Animation dazu
      for (int i = 0; i < maxMainNumber; i++) {
        _selectedMain[tipIndex][i] = currentMain.contains(i + 1);
      }
      for (int i = 0; i < maxEuroNumber; i++) {
        _selectedEuro[tipIndex][i] = currentEuro.contains(i + 1);
      }
    });

    // ==== Hauptzahlen-Lauflicht ====
    // Runde 1: kompletter Durchlauf 1..50
    for (int n = 1; n <= maxMainNumber; n++) {
      if (!mounted) return;
      setState(() {
        _highlightMainTip = tipIndex;
        _highlightMainNumber = n;
        if (finalMain.contains(n)) {
          _selectedMain[tipIndex][n - 1] = true;
        }
      });
      await Future.delayed(const Duration(milliseconds: 28));
    }

    // Runde 2: nur noch über die finalen Zahlen, zur Betonung
    for (final n in finalMain) {
      if (!mounted) return;
      setState(() {
        _highlightMainTip = tipIndex;
        _highlightMainNumber = n;
      });
      await Future.delayed(const Duration(milliseconds: 60));
    }

    setState(() {
      _highlightMainTip = null;
      _highlightMainNumber = null;
    });

    // ==== Eurozahlen-Lauflicht ====
    // Runde 1: kompletter Durchlauf 1..12
    for (int n = 1; n <= maxEuroNumber; n++) {
      if (!mounted) return;
      setState(() {
        _highlightEuroTip = tipIndex;
        _highlightEuroNumber = n;
        if (finalEuro.contains(n)) {
          _selectedEuro[tipIndex][n - 1] = true;
        }
      });
      await Future.delayed(const Duration(milliseconds: 70));
    }

    // Runde 2: nur über die finalen Eurozahlen
    for (final n in finalEuro) {
      if (!mounted) return;
      setState(() {
        _highlightEuroTip = tipIndex;
        _highlightEuroNumber = n;
      });
      await Future.delayed(const Duration(milliseconds: 90));
    }

    setState(() {
      _highlightEuroTip = null;
      _highlightEuroNumber = null;

      // Jetzt erst finale Kombi für Ergebnis-Chips übernehmen
      _generatedMain[tipIndex]
        ..clear()
        ..addAll(finalMain);
      _generatedEuro[tipIndex]
        ..clear()
        ..addAll(finalEuro);

      _isAnimating = false;
    });
  }

  // ============================================================
  //   Löschen
  // ============================================================

  void _clearTip(int tip) {
    if (_isAnimating) return;
    setState(() {
      for (int i = 0; i < maxMainNumber; i++) {
        _selectedMain[tip][i] = false;
      }
      for (int i = 0; i < maxEuroNumber; i++) {
        _selectedEuro[tip][i] = false;
      }
      _generatedMain[tip].clear();
      _generatedEuro[tip].clear();
    });
  }

  Future<void> _generateAll() async {
    if (_isAnimating) return;
    for (int t = 0; t < tipCount; t++) {
      await _generateTip(t);
    }
  }

  void _clearAll() {
    if (_isAnimating) return;
    for (int i = 0; i < tipCount; i++) {
      _clearTip(i);
    }
  }

  // ============================================================
  //   UI: Gitter Hauptzahlen (5×10)
  // ============================================================

  Widget _buildMainGrid(int tipIndex) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _ejLightBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ejBronze, width: 1),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: maxMainNumber,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final int num = index + 1;
          final bool sel = _selectedMain[tipIndex][index];
          final bool hi = (_highlightMainTip == tipIndex &&
              _highlightMainNumber == num);

          Color bg = sel ? _ejGold : _ejBeige;
          if (hi) {
            bg = _ejGold;
          }

          return GestureDetector(
            onTap: () => _toggleMain(tipIndex, index),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _ejBronze, width: 0.8),
              ),
              child: Center(
                child: Text(
                  '$num',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  //   UI: Eurozahlen-Gitter (2×6)
  // ============================================================

  Widget _buildEuroGrid(int tipIndex) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _ejEuroArea,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ejBronze, width: 1),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: maxEuroNumber,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final int num = index + 1;
          final bool sel = _selectedEuro[tipIndex][index];
          final bool hi = (_highlightEuroTip == tipIndex &&
              _highlightEuroNumber == num);

          Color bg = sel ? _ejGold : _ejBeige;
          if (hi) {
            bg = _ejGold;
          }

          return GestureDetector(
            onTap: () => _toggleEuro(tipIndex, index),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: _ejBronze, width: 0.8),
              ),
              child: Center(
                child: Text(
                  '$num',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // manuelles Togglen
  void _toggleMain(int t, int i) {
    if (_isAnimating) return;
    setState(() {
      final bool v = _selectedMain[t][i];
      if (v) {
        _selectedMain[t][i] = false;
      } else {
        int c = 0;
        for (int k = 0; k < maxMainNumber; k++) {
          if (_selectedMain[t][k]) c++;
        }
        if (c < mainNumbersPerTip) {
          _selectedMain[t][i] = true;
        }
      }
      // Wenn keine Animation läuft, aktuelle Auswahl als "Momentzustand" in Chips zeigen
      if (!_isAnimating) {
        _generatedMain[t] = [
          for (int k = 0; k < maxMainNumber; k++)
            if (_selectedMain[t][k]) k + 1
        ];
      }
    });
  }

  void _toggleEuro(int t, int i) {
    if (_isAnimating) return;
    setState(() {
      final bool v = _selectedEuro[t][i];
      if (v) {
        _selectedEuro[t][i] = false;
      } else {
        int c = 0;
        for (int k = 0; k < maxEuroNumber; k++) {
          if (_selectedEuro[t][k]) c++;
        }
        if (c < euroNumbersPerTip) {
          _selectedEuro[t][i] = true;
        }
      }
      if (!_isAnimating) {
        _generatedEuro[t] = [
          for (int k = 0; k < maxEuroNumber; k++)
            if (_selectedEuro[t][k]) k + 1
        ];
      }
    });
  }

  // ============================================================
  //   Ergebnis-Chips
  // ============================================================

  Widget _buildResultChips(int tipIndex) {
    // Während Animation keine Chips anzeigen (Spannung)
    if (_isAnimating) {
      return const SizedBox.shrink();
    }

    final List<int> main = _generatedMain[tipIndex];
    final List<int> euro = _generatedEuro[tipIndex];

    if (main.isEmpty && euro.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (main.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: main
                  .map(
                    (n) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _ejChipGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        n.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (euro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: euro
                    .map(
                      (n) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _ejChipGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          n.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  //   Tippfeld
  // ============================================================

  Widget _buildTip(int tip, bool isPortrait) {
    final bool hasAnySelection =
        _generatedMain[tip].isNotEmpty || _generatedEuro[tip].isNotEmpty;
    final bool isTipAnimating =
        _isAnimating && (_highlightMainTip == tip || _highlightEuroTip == tip);

    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _ejLightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ejBronze, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopfzeile mit Tipp-Label + Toggle-Button
          Row(
            children: [
              Text(
                'Tipp ${tip + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isAnimating
                    ? null
                    : hasAnySelection
                        ? () => _clearTip(tip)
                        : () => _generateTip(tip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAnimating
                      ? Colors.grey[500]
                      : hasAnySelection
                          ? Colors.red[700]
                          : Colors.green[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isTipAnimating
                      ? 'Läuft...'
                      : hasAnySelection
                          ? 'Löschen'
                          : 'Generieren',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildMainGrid(tip),
          const SizedBox(height: 6),
          const Text(
            'Eurozahlen',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          _buildEuroGrid(tip),
          _buildResultChips(tip),
        ],
      ),
    );
  }

  // ============================================================
  //   Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eurojackpot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text(
                    'Eurojackpot – 8 Tippfelder (5 aus 50 + 2 aus 12)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Feste 2x4-Matrix
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTip(0, isPortrait)),
                          Expanded(child: _buildTip(1, isPortrait)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildTip(2, isPortrait)),
                          Expanded(child: _buildTip(3, isPortrait)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildTip(4, isPortrait)),
                          Expanded(child: _buildTip(5, isPortrait)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildTip(6, isPortrait)),
                          Expanded(child: _buildTip(7, isPortrait)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Buttons unten – fixiert
          Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAnimating ? null : _generateAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'ALLE GENERIEREN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAnimating ? null : _clearAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'ALLES LÖSCHEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
  }
}
