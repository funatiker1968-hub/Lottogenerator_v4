import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Lotto 6aus49 Screen – 12 Tippfelder + Schein-Superzahl
/// Stand: 16.11.2025
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

  /// Für jedes Tippfeld (0–11) ein bool-Array für 1–49.
  final List<List<bool>> _selectedNumbers =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Finale gezogene Zahlen je Tipp (immer sortierte Liste mit bis zu 6 Zahlen).
  final List<List<int>> _finalNumbers =
      List.generate(tipCount, (_) => <int>[]);

  /// Für jedes Tippfeld die aktuell „laufende“ Zahl (Highlight).
  final List<int?> _currentHighlight = List<int?>.filled(tipCount, null);

  /// Läuft gerade eine Animation für diesen Tipp?
  final List<bool> _isAnimatingTip = List<bool>.filled(tipCount, false);

  /// Timer je Tipp für das Laufkreuz.
  final List<Timer?> _tipTimers = List<Timer?>.filled(tipCount, null);

  /// Schein-Superzahl (0–9)
  int _scheinSuperzahl = 0;
  bool _superzahlGenerated = false;
  bool _isSuperzahlAnimating = false;

  /// Wird gerade „Alles generieren“ ausgeführt?
  bool _isGeneratingAll = false;

  @override
  void dispose() {
    for (final timer in _tipTimers) {
      timer?.cancel();
    }
    super.dispose();
  }

  // ----------------------------------------------------------
  //  Superzahl
  // ----------------------------------------------------------

  /// Startet das Superzahl-Lauflicht (2 schnelle Runden, eine langsamer, dann Stop).
  Future<void> _runSuperzahlAnimation() async {
    if (_isSuperzahlAnimating) return;

    setState(() {
      _isSuperzahlAnimating = true;
      _superzahlGenerated = false;
    });

    final int finalNumber = _random.nextInt(10);

    const int cycles = 2; // 2 volle, schnelle Runden
    const int fastDelay = 70;
    const int slowDelay = 140;

    // Schnelle Runden
    for (int cycle = 0; cycle < cycles; cycle++) {
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;
        setState(() {
          _scheinSuperzahl = i;
        });
        await Future.delayed(const Duration(milliseconds: fastDelay));
      }
    }

    // Letzte langsamere Runde bis zur finalen Zahl
    for (int i = 0; i <= finalNumber; i++) {
      if (!mounted) return;
      setState(() {
        _scheinSuperzahl = i;
      });
      await Future.delayed(const Duration(milliseconds: slowDelay));
    }

    if (!mounted) return;
    setState(() {
      _scheinSuperzahl = finalNumber;
      _superzahlGenerated = true;
      _isSuperzahlAnimating = false;
    });
  }

  /// Superzahl per Tipp über Dialog manuell umstellen.
  void _onSuperzahlTap() {
    if (_isSuperzahlAnimating) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Superzahl wählen'),
          content: SizedBox(
            height: 180,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                final bool isSelected = index == _scheinSuperzahl;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _scheinSuperzahl = index;
                      _superzahlGenerated = true;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[900]!),
                    ),
                    child: Center(
                      child: Text(
                        index.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------
  //  Tipp-Logik
  // ----------------------------------------------------------

  /// Löscht ein Tippfeld komplett.
  void _clearTip(int tipIndex) {
    _tipTimers[tipIndex]?.cancel();
    _tipTimers[tipIndex] = null;

    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _selectedNumbers[tipIndex][i] = false;
      }
      _finalNumbers[tipIndex].clear();
      _currentHighlight[tipIndex] = null;
      _isAnimatingTip[tipIndex] = false;
    });
  }

  /// Löscht alle 12 Tippfelder und Superzahl.
  void _clearAll() {
    for (int i = 0; i < tipCount; i++) {
      _clearTip(i);
    }
    setState(() {
      _scheinSuperzahl = 0;
      _superzahlGenerated = false;
    });
  }

  /// Generiert eine Tipp-Kombination (6 unterschiedliche Zahlen 1–49).
  List<int> _generateRandomTip() {
    final List<int> pool = List.generate(maxNumber, (i) => i + 1);
    pool.shuffle(_random);
    final List<int> result = pool.take(numbersPerTip).toList()..sort();
    return result;
  }

  /// Startet für EIN Tippfeld das Laufkreuz + setzt final 6 Zahlen.
  Future<void> _runTipAnimation(int tipIndex) async {
    // alte Animation ggf. abbrechen
    _tipTimers[tipIndex]?.cancel();
    _tipTimers[tipIndex] = null;

    final List<int> finalNumbers = _generateRandomTip();

    setState(() {
      // alles löschen
      for (int i = 0; i < maxNumber; i++) {
        _selectedNumbers[tipIndex][i] = false;
      }
      _finalNumbers[tipIndex]
        ..clear()
        ..addAll(finalNumbers);
      _currentHighlight[tipIndex] = null;
      _isAnimatingTip[tipIndex] = true;
    });

    int current = 1;

    _tipTimers[tipIndex] = Timer.periodic(
      const Duration(milliseconds: 70), // Geschwindigkeit des Kreuzlaufs
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _currentHighlight[tipIndex] = current;

          // Wenn die aktuelle Zahl eine der 6 finalen ist -> dauerhaft markieren
          if (_finalNumbers[tipIndex].contains(current)) {
            _selectedNumbers[tipIndex][current - 1] = true;
          }
        });

        if (current >= maxNumber) {
          // alle 49 Positionen einmal besucht -> Animation Ende
          timer.cancel();
          setState(() {
            _isAnimatingTip[tipIndex] = false;
            _currentHighlight[tipIndex] = null;
          });
        } else {
          current++;
        }
      },
    );
  }

  /// Public-Handler für einen Tipp: ggf. Superzahl + Tipp-Animation.
  Future<void> _generateTip(int tipIndex) async {
    if (_isAnimatingTip[tipIndex]) return;

    // Wenn noch keine Superzahl da ist, zuerst Superzahl generieren.
    if (!_superzahlGenerated) {
      await _runSuperzahlAnimation();
      if (!mounted) return;
    }

    await _runTipAnimation(tipIndex);
  }

  /// Alle 12 Tipps nacheinander generieren (inkl. Superzahl).
  Future<void> _generateAllTips() async {
    if (_isGeneratingAll) return;

    setState(() {
      _isGeneratingAll = true;
    });

    // Superzahl zuerst
    if (!_superzahlGenerated) {
      await _runSuperzahlAnimation();
      if (!mounted) {
        _isGeneratingAll = false;
        return;
      }
    }

    // Tipp 1 bis 12 nacheinander
    for (int i = 0; i < tipCount; i++) {
      await _runTipAnimation(i);
      if (!mounted) {
        _isGeneratingAll = false;
        return;
      }
      // kleine Pause, damit man die Reihenfolge sieht
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() {
      _isGeneratingAll = false;
    });
  }

  // ----------------------------------------------------------
  //  UI-Bausteine
  // ----------------------------------------------------------

  /// Leiste oben: Schein-Superzahl 0–9 in 1×10 Grid, blau, Gridlinien dunkelrot.
  Widget _buildSuperzahlBar() {
    return GestureDetector(
      onTap: _onSuperzahlTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[900]!, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schein-Superzahl (Tippen zum Ändern)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 6,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final bool isSelected = index == _scheinSuperzahl;
                  final bool isHighlight = _isSuperzahlAnimating &&
                      index == _scheinSuperzahl;
                  return Container(
                    width: 36,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.yellow[300] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[900]!, width: 1.0),
                    ),
                    child: Center(
                      child: Text(
                        index.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isHighlight ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _superzahlGenerated
                  ? 'Aktuelle Superzahl: $_scheinSuperzahl'
                  : _isSuperzahlAnimating
                      ? 'Superzahl wird generiert...'
                      : 'Noch keine Superzahl generiert',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Einzelnes Tippfeld (postgelb, 7×7 Grid 1–49, Buttons darunter).
  Widget _buildTipCard(int tipIndex) {
    final List<bool> selected = _selectedNumbers[tipIndex];
    final List<int> finalNums = _finalNumbers[tipIndex];
    final int? highlight = _currentHighlight[tipIndex];
    final bool isAnimating = _isAnimatingTip[tipIndex];

    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.yellow[600],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[800]!, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            'Tipp ${tipIndex + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          // Zahlengitter 7×7, 1–49
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 1.5,
                mainAxisSpacing: 1.5,
                childAspectRatio: 1.0,
              ),
              itemCount: maxNumber,
              itemBuilder: (context, index) {
                final int number = index + 1;
                final bool isSelected = selected[index];
                final bool isFinal = finalNums.contains(number);
                final bool isHighlighted = highlight == number;

                Color bg;
                Color borderColor = Colors.red[900]!;
                Widget inner;

                if (isHighlighted && !isSelected) {
                  // Laufkreuz über nicht finalen Zahlen
                  bg = Colors.orange[300]!;
                  inner = const Text(
                    '✗',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  );
                } else if (isSelected && isFinal) {
                  // Finale, getroffene Zahlen
                  bg = Colors.yellow[800]!;
                  inner = const Text(
                    '✗',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                } else {
                  bg = Colors.yellow[200]!;
                  inner = Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: borderColor, width: 0.7),
                  ),
                  child: Center(child: inner),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // Buttons: Generieren / Löschen
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isAnimating ? null : () => _generateTip(tipIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: Text(
                    isAnimating ? 'Läuft...' : 'Generieren',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _clearTip(tipIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text(
                    'Löschen',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Button-Leiste unten: Alle generieren / alles löschen.
  Widget _buildBottomControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isGeneratingAll ? null : _generateAllTips,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              _isGeneratingAll ? 'Generiere alles...' : 'Alle generieren',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _clearAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text(
              'Alles löschen',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  //  Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final bool isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto 6aus49'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildSuperzahlBar(),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: isPortrait ? 2 : 4,
                childAspectRatio: isPortrait ? 0.90 : 1.05,
                children: List.generate(
                  tipCount,
                  (index) => _buildTipCard(index),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }
}
