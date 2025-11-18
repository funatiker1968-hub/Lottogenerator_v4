import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Lotto 6aus49 – 12 Tippfelder
/// Toggle-Button oben rechts (GENERIEREN ↔ LÖSCHEN)
/// Favoriten sofort sichtbar
/// Generierte Zahlen als X
/// Finale Ergebnisse am Ende der Animation
/// Global-Buttons unten fixiert

// Lotto-Farben
const Color _lottoYellow = Color(0xFFFFDD00);
const Color _lottoRed = Color(0xFFD20000);
const Color _lottoGrey = Color(0xFFF2F2F2);

class Lotto6aus49Screen extends StatefulWidget {
  const Lotto6aus49Screen({super.key});

  @override
  State<Lotto6aus49Screen> createState() => _Lotto6aus49ScreenState();
}

class _Lotto6aus49ScreenState extends State<Lotto6aus49Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int numbersPerTip = 6;

  final Random _random = Random();

  /// Auswahlstatus – Favoriten + generierte Zahlen
  final List<List<bool>> _selected =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Finale Zahlen eines Tipps (erst nach Animation sichtbar)
  final List<List<int>> _finalNumbers =
      List.generate(tipCount, (_) => <int>[]);

  /// Lauflicht pro Tipp
  final List<int?> _highlight = List<int?>.filled(tipCount, null);
  final List<bool> _isAnimatingTip = List<bool>.filled(tipCount, false);
  final List<Timer?> _tipTimers = List<Timer?>.filled(tipCount, null);

  /// Flags
  bool _isGeneratingAll = false;

  // ----------------------------------------------------------
  //  Tipp löschen
  // ----------------------------------------------------------

  void _clearTip(int tip) {
    _tipTimers[tip]?.cancel();
    _tipTimers[tip] = null;

    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _selected[tip][i] = false;
      }
      _highlight[tip] = null;
      _finalNumbers[tip].clear();
      _isAnimatingTip[tip] = false;
    });
  }

  void _clearAll() {
    for (int i = 0; i < tipCount; i++) {
      _clearTip(i);
    }
  }

  // ----------------------------------------------------------
  //  Tipp generieren (mit Animation)
  // ----------------------------------------------------------

  List<int> _generateRandomTipWithFavorites(int tip) {
    final List<int> favs = [];
    for (int i = 0; i < maxNumber; i++) {
      if (_selected[tip][i]) favs.add(i + 1);
    }

    final int need = numbersPerTip - favs.length;
    if (need <= 0) return favs..sort();

    final List<int> pool = [
      for (int n = 1; n <= maxNumber; n++)
        if (!favs.contains(n)) n
    ];
    pool.shuffle(_random);

    final List<int> newNums = pool.take(need).toList();
    return [...favs, ...newNums]..sort();
  }

  Future<void> _runTipAnimation(int tip) async {
    _tipTimers[tip]?.cancel();
    _tipTimers[tip] = null;

    final List<int> finalNumbers = _generateRandomTipWithFavorites(tip);

    setState(() {
      _finalNumbers[tip]
        ..clear()
        ..addAll(finalNumbers);

      for (int i = 0; i < maxNumber; i++) {
        if (!_finalNumbers[tip].contains(i + 1)) {
          _selected[tip][i] = false;
        }
      }

      _highlight[tip] = null;
      _isAnimatingTip[tip] = true;
    });

    int current = 1;

    _tipTimers[tip] = Timer.periodic(
      const Duration(milliseconds: 70),
      (timer) {
        if (!mounted) return;

        setState(() {
          _highlight[tip] = current;

          if (_finalNumbers[tip].contains(current)) {
            _selected[tip][current - 1] = true;
          }
        });

        if (current >= maxNumber) {
          timer.cancel();
          setState(() {
            _highlight[tip] = null;
            _isAnimatingTip[tip] = false;
          });
        } else {
          current++;
        }
      },
    );
  }

  Future<void> _generateTip(int tip) async {
    if (_isAnimatingTip[tip]) return;
    await _runTipAnimation(tip);
  }

  Future<void> _generateAllTips() async {
    if (_isGeneratingAll) return;

    setState(() {
      _isGeneratingAll = true;
    });

    for (int i = 0; i < tipCount; i++) {
      await _generateTip(i);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() {
      _isGeneratingAll = false;
    });
  }

  // ----------------------------------------------------------
  //  UI: Tippfeld
  // ----------------------------------------------------------

  Widget _buildTipCard(int tip) {
    final bool isAnimating = _isAnimatingTip[tip];
    final bool hasFinal = _finalNumbers[tip].isNotEmpty;
    final int? highlight = _highlight[tip];
    final List<bool> selected = _selected[tip];

    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.yellow[600],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[800]!, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + TOGGLE BUTTON
          Row(
            children: [
              Text(
                'Tipp ${tip + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isAnimating
                    ? null
                    : hasFinal
                        ? () => _clearTip(tip)
                        : () => _generateTip(tip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnimating
                      ? Colors.grey[600]
                      : hasFinal
                          ? Colors.red[700]
                          : Colors.green[700],
                  minimumSize: const Size(10, 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isAnimating
                      ? 'Läuft...'
                      : hasFinal
                          ? 'Löschen'
                          : 'Generieren',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Gitter
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: maxNumber,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 1.5,
              mainAxisSpacing: 1.5,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final int number = index + 1;
              final bool isSel = selected[index];
              final bool isFinal = _finalNumbers[tip].contains(number);
              final bool isHi = highlight == number;

              Color bg;
              Color textColor = Colors.black;
              Widget inner;

              if (isHi && !isSel) {
                bg = _lottoYellow;
                inner = const Text('✗',
                    style: TextStyle(
                        color: _lottoRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 14));
              } else if (isFinal) {
                bg = _lottoYellow;
                inner = const Text('✗',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14));
              } else if (isSel) {
                bg = _lottoGrey;
                inner = Text(
                  '$number',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                );
              } else {
                bg = _lottoGrey;
                inner = Text(
                  '$number',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _lottoRed, width: 0.7),
                ),
                child: Center(child: inner),
              );
            },
          ),

          if (hasFinal) const SizedBox(height: 6),

          // Finale Zahlen unten anzeigen
          if (hasFinal)
            Wrap(
              spacing: 6,
              children: _finalNumbers[tip]
                  .map(
                    (n) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$n',
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
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  //  Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto 6aus49'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.count(
                crossAxisCount: isPortrait ? 2 : 3,
                childAspectRatio: isPortrait ? 0.90 : 1.05,
                children: List.generate(
                  tipCount,
                  (index) => _buildTipCard(index),
                ),
              ),
            ),
          ),

          // Fixierte Buttons unten
          Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isGeneratingAll ? null : _generateAllTips,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _isGeneratingAll
                          ? 'Generiere alles...'
                          : 'Alle generieren',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Alles löschen',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
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
