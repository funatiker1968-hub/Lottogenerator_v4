import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Lotto 6aus49 – Version mit:
/// - Favoriten (manuell)
/// - Generierten Zahlen (hellblau hinterlegt)
/// - X-Darstellung:
///     Favorit  = schwarzes X auf gelb
///     Generiert = rotes X auf hellblau
/// - Zahlentext unter jedem Tipp (Favorit schwarz, generiert rot)
/// - Toggle-Button pro Tipp oben rechts (GENERIEREN / LÖSCHEN / LÄUFT...)
/// - Master-Button unten (ALLE GENERIEREN / ALLES LÖSCHEN / GENERIIERE ALLES...)
/// - Superzahl mit drehender Kugel + synchroner Leiste + Blink-Effekt

const Color _lottoYellow = Color(0xFFFFDD00);
const Color _lottoRed = Color(0xFFD20000);
const Color _lottoGrey = Color(0xFFF2F2F2);

/// Hintergrundfarbe für generierte Zahlen
const Color _generatedBlue = Color(0xFFBEE6FF);

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

  /// Favoriten (manuell gesetzte Zahlen)
  final List<List<bool>> _favorites =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Generierte Zahlen
  final List<List<bool>> _generated =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Aktuelle Highlight-Zahl im Tipp (Lauflicht)
  final List<int?> _currentHighlight =
      List<int?>.filled(tipCount, null);

  /// Läuft gerade eine Animation in diesem Tipp?
  final List<bool> _isAnimatingTip =
      List<bool>.filled(tipCount, false);

  /// Timer je Tipp für das Lauflicht
  final List<Timer?> _tipTimers =
      List<Timer?>.filled(tipCount, null);

  /// Superzahl (Schein)
  int _scheinSuperzahl = 0;
  bool _superzahlGenerated = false;
  bool _isSuperzahlAnimating = false;

  /// Superzahl-Kugel Rotation (Anzahl Umdrehungen)
  double _superBallTurns = 0.0;

  /// Blink-Status für finale Superzahl in der Leiste
  bool _isSuperzahlBlinking = false;
  bool _superzahlBlinkOn = false;

  /// Wird gerade „Alle generieren“ ausgeführt?
  bool _isGeneratingAll = false;

  @override
  void dispose() {
    for (final timer in _tipTimers) {
      timer?.cancel();
    }
    super.dispose();
  }

  // ----------------------------------------------------------
  // Superzahl – Animation mit drehender Kugel
  // ----------------------------------------------------------

  Future<void> _runSuperzahlAnimation() async {
    if (_isSuperzahlAnimating) return;

    setState(() {
      _isSuperzahlAnimating = true;
      _superzahlGenerated = false;
      _isSuperzahlBlinking = false;
      _superzahlBlinkOn = false;
      _superBallTurns = 0.0;
    });

    final int finalNumber = _random.nextInt(10);

    const int cycles = 2;
    const int fastDelay = 70;
    const int slowDelay = 140;

    // Schnelle Runden (0–9) – Kugel dreht mit
    for (int cycle = 0; cycle < cycles; cycle++) {
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;
        setState(() {
          _scheinSuperzahl = i;
          _superBallTurns += 0.25; // 1/4 Umdrehung pro Schritt
        });
        await Future.delayed(const Duration(milliseconds: fastDelay));
      }
    }

    // Langsamer bis zur Finalzahl
    for (int i = 0; i <= finalNumber; i++) {
      if (!mounted) return;
      setState(() {
        _scheinSuperzahl = i;
        _superBallTurns += 0.20;
      });
      await Future.delayed(const Duration(milliseconds: slowDelay));
    }

    if (!mounted) return;
    setState(() {
      _scheinSuperzahl = finalNumber;
      _superzahlGenerated = true;
      _isSuperzahlAnimating = false;
      // Blinkphase starten
      _isSuperzahlBlinking = true;
      _superzahlBlinkOn = false;
    });

    // Finale Zahl in der Leiste 5x blinken (10 Toggles)
    for (int i = 0; i < 10; i++) {
      if (!mounted) return;
      setState(() {
        _superzahlBlinkOn = !_superzahlBlinkOn;
      });
      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (!mounted) return;
    setState(() {
      _isSuperzahlBlinking = false;
      _superzahlBlinkOn = false;
    });
  }

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
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                      color: isSelected ? _lottoYellow : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _lottoRed),
                    ),
                    child: Center(
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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

  Widget _buildSuperzahlBall() {
    return AnimatedRotation(
      turns: _superBallTurns,
      duration: const Duration(milliseconds: 80),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: _lottoRed, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$_scheinSuperzahl',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuperzahlBar() {
    return GestureDetector(
      onTap: _onSuperzahlTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _lottoRed, width: 1.4),
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

            // Leiste + Kugel nebeneinander
            Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                        final bool isBlinkDigit = _isSuperzahlBlinking &&
                            _superzahlBlinkOn &&
                            isSelected;

                        Color bg = isSelected ? _lottoYellow : Colors.blue[100]!;
                        Color textColor = Colors.black;

                        if (isBlinkDigit) {
                          bg = _lottoRed;
                          textColor = Colors.white;
                        }

                        return Container(
                          width: 36,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: _lottoRed, width: 1.0),
                          ),
                          child: Center(
                            child: Text(
                              index.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSuperzahlBall(),
              ],
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

  // ----------------------------------------------------------
  // Tipp-Status-Helfer
  // ----------------------------------------------------------

  bool _tipHasFavorites(int tip) {
    for (int i = 0; i < maxNumber; i++) {
      if (_favorites[tip][i]) return true;
    }
    return false;
  }

  bool _tipHasGenerated(int tip) {
    for (int i = 0; i < maxNumber; i++) {
      if (_generated[tip][i]) return true;
    }
    return false;
  }

  bool _anyTipHasContent() {
    for (int t = 0; t < tipCount; t++) {
      if (_tipHasFavorites(t) || _tipHasGenerated(t)) return true;
    }
    return false;
  }

  // ----------------------------------------------------------
  // Tipp löschen
  // ----------------------------------------------------------

  void _clearTip(int tip) {
    _tipTimers[tip]?.cancel();
    _tipTimers[tip] = null;

    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _favorites[tip][i] = false;
        _generated[tip][i] = false;
      }
      _currentHighlight[tip] = null;
      _isAnimatingTip[tip] = false;
    });
  }

  void _clearAll() {
    for (int t = 0; t < tipCount; t++) {
      _clearTip(t);
    }
    setState(() {
      _scheinSuperzahl = 0;
      _superzahlGenerated = false;
    });
  }

  // ----------------------------------------------------------
  // Tipp generieren (mit Favoriten)
  // ----------------------------------------------------------

  Future<void> _runTipAnimation(int tip) async {
    _tipTimers[tip]?.cancel();
    _tipTimers[tip] = null;

    // Favoriten einsammeln
    final List<int> favs = [];
    for (int i = 0; i < maxNumber; i++) {
      if (_favorites[tip][i]) favs.add(i + 1);
    }

    int need = numbersPerTip - favs.length;
    if (need < 0) need = 0;

    final List<int> pool = [
      for (int n = 1; n <= maxNumber; n++)
        if (!favs.contains(n)) n,
    ];
    pool.shuffle(_random);
    final List<int> newGen = pool.take(need).toList();

    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _generated[tip][i] = false;
      }
      _isAnimatingTip[tip] = true;
      _currentHighlight[tip] = null;
    });

    final Set<int> finalSet = {...favs, ...newGen};
    int current = 1;

    _tipTimers[tip] = Timer.periodic(
      const Duration(milliseconds: 70),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _currentHighlight[tip] = current;

          if (finalSet.contains(current)) {
            final bool isFav = favs.contains(current);
            if (isFav) {
              _favorites[tip][current - 1] = true;
            } else {
              _generated[tip][current - 1] = true;
            }
          }
        });

        if (current >= maxNumber) {
          timer.cancel();
          setState(() {
            _isAnimatingTip[tip] = false;
            _currentHighlight[tip] = null;
          });
        } else {
          current++;
        }
      },
    );
  }

  Future<void> _generateTip(int tip) async {
    if (_isAnimatingTip[tip] || _isGeneratingAll) return;

    if (!_superzahlGenerated) {
      await _runSuperzahlAnimation();
      if (!mounted) return;
    }

    await _runTipAnimation(tip);
  }

  Future<void> _generateAllTips() async {
    if (_isGeneratingAll) return;

    setState(() {
      _isGeneratingAll = true;
    });

    if (!_superzahlGenerated) {
      await _runSuperzahlAnimation();
      if (!mounted) {
        _isGeneratingAll = false;
        return;
      }
    }

    for (int t = 0; t < tipCount; t++) {
      await _runTipAnimation(t);
      if (!mounted) {
        _isGeneratingAll = false;
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() {
      _isGeneratingAll = false;
    });
  }

  // ----------------------------------------------------------
  // Manuelles Togglen einer Zahl
  // ----------------------------------------------------------

  void _toggleNumber(int tip, int index) {
    if (_isAnimatingTip[tip] || _isGeneratingAll) return;

    setState(() {
      final bool isFav = _favorites[tip][index];
      final bool isGen = _generated[tip][index];

      if (!isFav && !isGen) {
        // neue Favoritenzahl, aber max. 6 insgesamt
        int count = 0;
        for (int i = 0; i < maxNumber; i++) {
          if (_favorites[tip][i] || _generated[tip][i]) {
            count++;
          }
        }
        if (count >= numbersPerTip) return;
        _favorites[tip][index] = true;
      } else if (isFav && !isGen) {
        _favorites[tip][index] = false;
      } else if (!isFav && isGen) {
        _generated[tip][index] = false;
      } else {
        _favorites[tip][index] = false;
        _generated[tip][index] = false;
      }
    });
  }

  // ----------------------------------------------------------
  // Tippfeld UI
  // ----------------------------------------------------------

  Widget _buildTipCard(int tip) {
    final bool isAnimating = _isAnimatingTip[tip] || _isGeneratingAll;
    final int? highlight = _currentHighlight[tip];

    final bool hasGen = _tipHasGenerated(tip);

    // finale Zahlenliste für Anzeige unten
    final List<int> finalNums = [];
    for (int i = 0; i < maxNumber; i++) {
      if (_favorites[tip][i] || _generated[tip][i]) {
        finalNums.add(i + 1);
      }
    }
    finalNums.sort();

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
          // Kopfzeile mit Tipp-Label + Toggle-Button
          Row(
            children: [
              Text(
                'Tipp ${tip + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isAnimating
                    ? null
                    : hasGen
                        ? () => _clearTip(tip)
                        : () => _generateTip(tip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnimating
                      ? Colors.grey[600]
                      : hasGen
                          ? Colors.red[700]
                          : Colors.green[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isAnimating
                      ? 'LÄUFT...'
                      : hasGen
                          ? 'LÖSCHEN'
                          : 'GENERIEREN',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Zahlengitter 1–49
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 1.5,
              mainAxisSpacing: 1.5,
              childAspectRatio: 0.88,
            ),
            itemCount: maxNumber,
            itemBuilder: (context, index) {
              final int number = index + 1;
              final bool isFav = _favorites[tip][index];
              final bool isGen = _generated[tip][index];
              final bool isFinal = isFav || isGen;
              final bool isHi = highlight == number;

              Color bg;
              Widget inner;

              if (isHi && !isFinal) {
                // laufendes Kreuz auf noch nicht finalen Feldern
                bg = _lottoYellow;
                inner = const Text(
                  '✗',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _lottoRed,
                  ),
                );
              } else if (isFinal) {
                // finale Zahlen
                bg = isFav ? _lottoYellow : _generatedBlue;
                inner = Text(
                  '✗',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isFav ? Colors.black : _lottoRed,
                  ),
                );
              } else {
                // normale Zahl
                bg = _lottoGrey;
                inner = Text(
                  number.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _toggleNumber(tip, index),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _lottoRed, width: 0.7),
                  ),
                  child: Center(child: inner),
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // Finale Zahlenliste unten (nur wenn nicht animiert)
          if (!isAnimating && finalNums.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  const Text(
                    'Zahlen:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  ...finalNums.map((n) {
                    final bool isFav = _favorites[tip][n - 1];
                    final bool isGen = _generated[tip][n - 1];
                    final Color c =
                        isFav ? Colors.black : (isGen ? _lottoRed : Colors.black);
                    return Text(
                      n.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: c,
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Master-Button unten
  // ----------------------------------------------------------

  Widget _buildBottomMasterButton() {
    final bool anyContent = _anyTipHasContent();

    String label;
    Color color;
    VoidCallback? onPressed;

    if (_isGeneratingAll) {
      label = 'GENERIIERE ALLES...';
      color = Colors.grey[700]!;
      onPressed = null;
    } else if (anyContent) {
      label = 'ALLES LÖSCHEN';
      color = Colors.red[700]!;
      onPressed = _clearAll;
    } else {
      label = 'ALLE GENERIEREN';
      color = Colors.green[700]!;
      onPressed = _generateAllTips;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

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
                itemCount: tipCount,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isPortrait ? 2 : 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: isPortrait ? 300 : 260,
                ),
                itemBuilder: (context, index) => _buildTipCard(index),
              ),
            ),
            const SizedBox(height: 4),
            _buildBottomMasterButton(),
          ],
        ),
      ),
    );
  }
}

