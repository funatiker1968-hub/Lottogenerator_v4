import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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

  /// Manuell gesetzte Lieblingszahlen (dürfen beim Generieren nicht überschrieben werden).
  final List<List<bool>> _favorite =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Vom Generator gesetzte Zahlen (dürfen überschrieben / gelöscht werden).
  final List<List<bool>> _generated =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Aktuell animierter Tipp (für Lauflicht).
  int? _animatingTipIndex;

  /// Gerade hervorgehobene Zahl im Lauflicht (1–49).
  int? _currentHighlightNumber;

  /// Schein-Superzahl (0–9).
  int _scheinSuperzahl = 0;
  bool _superzahlGenerated = false;
  bool _superzahlAnimating = false;

  /// Wird gerade "Alle generieren" ausgeführt?
  bool _isGeneratingAll = false;

  List<int> _selectedNumbersForTip(int tipIndex) {
    final result = <int>[];
    for (int i = 0; i < maxNumber; i++) {
      if (_favorite[tipIndex][i] || _generated[tipIndex][i]) {
        result.add(i + 1);
      }
    }
    return result;
  }

  void _onNumberTap(int tipIndex, int number) {
    if (_animatingTipIndex == tipIndex || _isGeneratingAll) return;

    final idx = number - 1;

    setState(() {
      final isFav = _favorite[tipIndex][idx];
      final isGen = _generated[tipIndex][idx];

      // Wenn Zahl schon gesetzt (Favorit oder generiert): komplett entfernen
      if (isFav || isGen) {
        _favorite[tipIndex][idx] = false;
        _generated[tipIndex][idx] = false;
      } else {
        // Neue Lieblingszahl setzen – aber max. 6 Zahlen pro Tipp
        final currentCount = _selectedNumbersForTip(tipIndex).length;
        if (currentCount >= numbersPerTip) {
          return;
        }
        _favorite[tipIndex][idx] = true;
      }
    });
  }

  Future<void> _generateTip(int tipIndex) async {
    if (_animatingTipIndex != null || _isGeneratingAll) return;

    // Favoriten einsammeln
    final favorites = <int>[];
    for (int i = 0; i < maxNumber; i++) {
      if (_favorite[tipIndex][i]) {
        favorites.add(i + 1);
      }
    }

    // Zu viele Favoriten: nur die ersten 6 bleiben, Rest wird entfernt
    if (favorites.length > numbersPerTip) {
      final keep = favorites.take(numbersPerTip).toSet();
      setState(() {
        for (int i = 0; i < maxNumber; i++) {
          final n = i + 1;
          _favorite[tipIndex][i] = keep.contains(n);
          _generated[tipIndex][i] = false;
        }
      });
      return;
    }

    final toGenerate = numbersPerTip - favorites.length;
    if (toGenerate <= 0) {
      // Nichts zu generieren – generierte Zahlen ggf. aufräumen
      setState(() {
        for (int i = 0; i < maxNumber; i++) {
          if (!_favorite[tipIndex][i]) {
            _generated[tipIndex][i] = false;
          }
        }
      });
      return;
    }

    // Kandidaten-Pool: alle Zahlen außer Favoriten
    final pool = List<int>.generate(maxNumber, (i) => i + 1)
      ..removeWhere((n) => favorites.contains(n));
    pool.shuffle(_random);
    final newNumbers = pool.take(toGenerate).toList()..sort();

    // Lauflicht vorbereiten
    setState(() {
      _animatingTipIndex = tipIndex;
      _currentHighlightNumber = 1;
      // alte generierte Zahlen löschen, Favoriten bleiben
      for (int i = 0; i < maxNumber; i++) {
        if (!_favorite[tipIndex][i]) {
          _generated[tipIndex][i] = false;
        }
      }
    });

    // Lauflicht: Kreuz einmal über alle 49 Zahlen
    for (int n = 1; n <= maxNumber; n++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 40));
      setState(() {
        _currentHighlightNumber = n;
      });
    }

    if (!mounted) return;

    // Neue generierte Zahlen setzen
    setState(() {
      for (final n in newNumbers) {
        _generated[tipIndex][n - 1] = true;
      }
      _animatingTipIndex = null;
      _currentHighlightNumber = null;
    });
  }

  void _clearTip(int tipIndex) {
    if (_animatingTipIndex == tipIndex || _isGeneratingAll) return;
    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _favorite[tipIndex][i] = false;
        _generated[tipIndex][i] = false;
      }
    });
  }

  Future<void> _runSuperzahlAnimation() async {
    setState(() {
      _superzahlAnimating = true;
    });

    final int finalNumber = _random.nextInt(10);

    // Zwei schnelle Runden 0–9
    const int cycles = 2;
    for (int c = 0; c < cycles; c++) {
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 90));
        setState(() {
          _scheinSuperzahl = i;
        });
      }
    }

    // Dritte Runde: langsamer bis zur finalen Zahl
    for (int i = 0; i <= finalNumber; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 180));
      setState(() {
        _scheinSuperzahl = i;
      });
    }

    if (!mounted) return;
    setState(() {
      _superzahlGenerated = true;
      _superzahlAnimating = false;
    });
  }

  void _onSuperzahlTap() {
    if (!_superzahlGenerated || _isGeneratingAll || _superzahlAnimating) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Superzahl wählen'),
        content: SizedBox(
          height: 120,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 10,
            itemBuilder: (_, index) {
              final isSelected = index == _scheinSuperzahl;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _scheinSuperzahl = index;
                  });
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade700),
                  ),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _generateAllTips() async {
    if (_isGeneratingAll) return;

    setState(() {
      _isGeneratingAll = true;
    });

    // Superzahl zuerst mit Lauflicht
    await _runSuperzahlAnimation();

    // Tipp 1–12 nacheinander generieren
    for (int t = 0; t < tipCount; t++) {
      await _generateTip(t);
    }

    if (!mounted) return;
    setState(() {
      _isGeneratingAll = false;
    });
  }

  void _clearAllTips() {
    if (_isGeneratingAll) return;
    setState(() {
      for (int t = 0; t < tipCount; t++) {
        for (int i = 0; i < maxNumber; i++) {
          _favorite[t][i] = false;
          _generated[t][i] = false;
        }
      }
      _scheinSuperzahl = 0;
      _superzahlGenerated = false;
      _superzahlAnimating = false;
      _animatingTipIndex = null;
      _currentHighlightNumber = null;
    });
  }

  Widget _buildSuperzahlBar() {
    return GestureDetector(
      onTap: _onSuperzahlTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade900, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schein-Superzahl',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 4,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final bool isActive = index == _scheinSuperzahl;
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.yellow.shade400
                          : Colors.blue.shade400,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade900, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        index.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black : Colors.white,
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
                  ? 'Superzahl: $_scheinSuperzahl'
                  : (_superzahlAnimating
                      ? 'Lauflicht...'
                      : 'Noch nicht generiert'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(int tipIndex) {
    final selectedNumbers = _selectedNumbersForTip(tipIndex);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF59D), // Postgelb
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade800),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipp ${tipIndex + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: maxNumber,
              itemBuilder: (context, index) {
                final number = index + 1;
                final idx = index;

                final isFav = _favorite[tipIndex][idx];
                final isGen = _generated[tipIndex][idx];
                final isSelected = isFav || isGen;
                final isHighlight = _animatingTipIndex == tipIndex &&
                    _currentHighlightNumber == number;

                Color bg;
                Color fg = Colors.black;
                String text;

                if (isHighlight && !isSelected) {
                  bg = Colors.red.shade700;
                  fg = Colors.white;
                  text = '✗';
                } else if (isFav) {
                  bg = Colors.green.shade600;
                  fg = Colors.white;
                  text = number.toString();
                } else if (isGen) {
                  bg = Colors.blue.shade600;
                  fg = Colors.white;
                  text = number.toString();
                } else {
                  bg = Colors.white;
                  text = number.toString();
                }

                return GestureDetector(
                  onTap: () => _onNumberTap(tipIndex, number),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: Colors.red.shade900, width: 0.7),
                    ),
                    child: Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _generateTip(tipIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text(
                    'GENERIEREN',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _clearTip(tipIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text(
                    'LÖSCHEN',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            selectedNumbers.isEmpty
                ? 'Noch keine Zahlen'
                : 'Zahlen: ${selectedNumbers.join(', ')}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    final crossAxisCount = isPortrait ? 2 : 3;
    final childAspect = isPortrait ? 0.9 : 1.0;

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
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: childAspect,
                ),
                itemCount: tipCount,
                itemBuilder: (context, index) {
                  return _buildTipCard(index);
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingAll ? null : _generateAllTips,
                    icon: const Icon(Icons.auto_mode, size: 18),
                    label: const Text('Alle generieren'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllTips,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Alles löschen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
