import 'dart:math';
import 'package:flutter/material.dart';

/// Lotto 6aus49 Screen
/// Version: 2025-11-16 15:47
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

  /// Für jedes Tippfeld merken wir, welche Zahlen angekreuzt sind (49 pro Tipp).
  final List<List<bool>> _selectedNumbers =
      List.generate(tipCount, (_) => List<bool>.filled(maxNumber, false));

  /// Die aktuell gesetzten Zahlen pro Tipp (immer sortiert).
  final List<List<int>> _generatedTips =
      List.generate(tipCount, (_) => <int>[]);

  /// Welches Tippfeld ist aktiv (0–11)?
  int _currentTipIndex = 0;

  /// Schein-Superzahl (0–9).
  int _scheinSuperzahl = 0;
  bool _superzahlGenerated = false;

  /// Wird gerade automatisch generiert?
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _resetAll();
  }

  void _resetAll() {
    for (int t = 0; t < tipCount; t++) {
      for (int i = 0; i < maxNumber; i++) {
        _selectedNumbers[t][i] = false;
      }
      _generatedTips[t].clear();
    }
    _currentTipIndex = 0;
    _scheinSuperzahl = 0;
    _superzahlGenerated = false;
  }

  void _clearCurrentTip() {
    final int tip = _currentTipIndex;
    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _selectedNumbers[tip][i] = false;
      }
      _generatedTips[tip].clear();
    });
  }

  void _generateSuperzahl() {
    setState(() {
      _scheinSuperzahl = _random.nextInt(10);
      _superzahlGenerated = true;
    });
  }

  void _onSuperzahlTap() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Superzahl wählen'),
          content: SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
                      color: isSelected ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  void _onNumberTap(int number) {
    if (_isGenerating) return;

    final int tip = _currentTipIndex;
    final int index = number - 1;

    setState(() {
      final bool currentlySelected = _selectedNumbers[tip][index];

      if (currentlySelected) {
        // Zahl löschen
        _selectedNumbers[tip][index] = false;
      } else {
        // Nur hinzufügen, wenn noch weniger als 6 Zahlen
        final int countSelected =
            _selectedNumbers[tip].where((value) => value).length;
        if (countSelected >= numbersPerTip) {
          return;
        }
        _selectedNumbers[tip][index] = true;
      }

      // Tipp neu aus den gesetzten Zahlen berechnen
      final List<int> newTip = [];
      for (int i = 0; i < maxNumber; i++) {
        if (_selectedNumbers[tip][i]) {
          newTip.add(i + 1);
        }
      }
      newTip.sort();
      _generatedTips[tip]
        ..clear()
        ..addAll(newTip);
    });
  }

  void _generateTip(int tipIndex) {
    final Set<int> numbers = <int>{};
    while (numbers.length < numbersPerTip) {
      numbers.add(_random.nextInt(maxNumber) + 1);
    }
    final List<int> result = numbers.toList()..sort();

    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _selectedNumbers[tipIndex][i] = false;
      }
      for (final n in result) {
        _selectedNumbers[tipIndex][n - 1] = true;
      }
      _generatedTips[tipIndex]
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _generateAllTips() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _resetAll();
    });

    // Superzahl zuerst
    _generateSuperzahl();

    // Alle 12 Tipps nacheinander
    for (int t = 0; t < tipCount; t++) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = t;
      });
      _generateTip(t);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _currentTipIndex = 0;
    });
  }

  Widget _buildSuperzahlSection(Orientation orientation) {
    final bool isPortrait = orientation == Orientation.portrait;
    final double height = isPortrait ? 70 : 50;
    final double fontSize = isPortrait ? 28 : 22;

    return GestureDetector(
      onTap: _onSuperzahlTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          children: [
            const Text(
              'Schein-Superzahl',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _scheinSuperzahl.toString(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: _superzahlGenerated ? Colors.blue : Colors.orange,
                  ),
                ),
              ),
            ),
            if (_isGenerating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildTipSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List<Widget>.generate(tipCount, (index) {
        final bool isActive = index == _currentTipIndex;
        final bool hasNumbers = _generatedTips[index].isNotEmpty;
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
          avatar: Icon(
            hasNumbers ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
          ),
        );
      }),
    );
  }

  Widget _buildNumberGrid(Orientation orientation) {
    final bool isPortrait = orientation == Orientation.portrait;
    final int crossAxisCount = isPortrait ? 7 : 10;
    final double aspectRatio = isPortrait ? 1.0 : 0.9;

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: aspectRatio,
      ),
      itemCount: maxNumber,
      itemBuilder: (context, index) {
        final int number = index + 1;
        final bool isSelected =
            _selectedNumbers[_currentTipIndex][number - 1];

        Color background;
        Color textColor;

        if (isSelected) {
          background = Colors.blue;
          textColor = Colors.white;
        } else {
          background = Colors.grey.shade300;
          textColor = Colors.black;
        }

        return GestureDetector(
          onTap: () => _onNumberTap(number),
          child: Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: isPortrait ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTipInfo() {
    final List<int> tipNumbers = _generatedTips[_currentTipIndex];

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(
            'Tipp ${_currentTipIndex + 1}: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (tipNumbers.isEmpty)
            const Text(
              'Noch keine Zahlen',
              style: TextStyle(color: Colors.grey),
            )
          else
            Expanded(
              child: Wrap(
                spacing: 6,
                children: tipNumbers
                    .map(
                      (n) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          n.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
  Widget _buildScheinUebersicht() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schein-Übersicht',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...List<Widget>.generate(tipCount, (index) {
            final List<int> tipNumbers = _generatedTips[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    'Tipp ${index + 1}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (tipNumbers.isEmpty)
                    const Text(
                      '–',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: tipNumbers
                            .map(
                              (n) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  n.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Superzahl: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _scheinSuperzahl.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateAllTips,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              _isGenerating ? 'Generiere...' : 'Alle Tipps generieren',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _clearCurrentTip,
            icon: const Icon(Icons.delete),
            label: const Text('Aktuellen Tipp löschen'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isGenerating
                ? null
                : () {
                    setState(() {
                      _resetAll();
                    });
                  },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Alles löschen'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lotto 6aus49'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSuperzahlSection(orientation),
                const SizedBox(height: 8),
                _buildTipSelector(),
                const SizedBox(height: 8),
                Expanded(
                  flex: 2,
                  child: _buildNumberGrid(orientation),
                ),
                _buildCurrentTipInfo(),
                const SizedBox(height: 8),
                _buildControlButtons(),
                const SizedBox(height: 8),
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: _buildScheinUebersicht(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
