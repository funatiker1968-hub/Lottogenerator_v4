import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Lotto 6aus49 – Version mit:
/// - 7×7 Grid (1–49) vollständig sichtbar (angepasste Kartenhöhe)
/// - Favoriten (manuell): gelb + schwarzes ✗
/// - Generierte Zahlen: hellblau + rotes ✗
/// - Normale Zahlen: hellgrau + schwarze Ziffer
/// - Zahlenliste unter jedem Tipp (schwarz / generiert rot)
/// - Toggle-Button pro Tipp oben rechts (GENERIEREN / LÖSCHEN / LÄUFT...)
/// - Master-Button unten (ALLE GENERIEREN / ALLES LÖSCHEN / GENERIIERE ALLES...)
/// - Superzahl: separate animierte Kugel + eigener Start-Button
/// - Superzahl-Leiste: finale Zahl blinkt 5×
/// - Globaler Sound-Toggle (Icon im AppBar) – Sound-Hooks vorbereitet

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

class _Lotto6aus49ScreenState extends State<Lotto6aus49Screen>
    with SingleTickerProviderStateMixin {
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

  /// Aktuelle Highlight-Zahl im Tipp (Lauflicht / Snake-Weg)
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

  /// Animationszustand Superzahl-Kugel
  late final AnimationController _superBallController;
  bool _isSuperBallSpinning = false;
  bool _isSuperzahlBlinkOn = false;

  /// Globaler Flag: wird gerade „Alle generieren“ ausgeführt?
  bool _isGeneratingAll = false;

  /// Globaler Sound-Schalter (für Superzahl + Snake)
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _superBallController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (final timer in _tipTimers) {
      timer?.cancel();
    }
    _superBallController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Sound-Hooks (noch ohne echte Audio-Implementierung)
  // ----------------------------------------------------------

  void _playSuperzahlSpinStart() {
    if (!_soundEnabled) return;
    LGSounds.playSpinStart();
  }

  void _playSuperzahlSpinEnd() {
    if (!_soundEnabled) return;
    LGSounds.playSpinEnd();
  }

  void _playSnakeStartSound() {
    if (!_soundEnabled) return;
    LGSounds.playSpinStart();
  }

  void _playSnakeEatSound() {
    if (!_soundEnabled) return;
    LGSounds.playSnakeEat();
  }

  void _playSnakeEndSound() {
    if (!_soundEnabled) return;
    LGSounds.playSnakeEnd();
  }

  // ----------------------------------------------------------
  // Superzahl – Kugel + Leiste
  // ----------------------------------------------------------

  Future<void> _runSuperzahlAnimation() async {
    if (_isSuperBallSpinning) return;

    setState(() {
      _isSuperBallSpinning = true;
      _superzahlGenerated = false;
      _isSuperzahlBlinkOn = false;
    });

    _playSuperzahlSpinStart();

    final int finalNumber = _random.nextInt(10);
    int current = _scheinSuperzahl;
    int delay = 60;

    // Schneller Teil
    for (int i = 0; i < 20; i++) {
      if (!mounted) return;
      await _superBallController.forward(from: 0);
      setState(() {
        current = (current + 1) % 10;
        _scheinSuperzahl = current;
      });
      await Future.delayed(Duration(milliseconds: delay));
      if (i > 10) delay += 10;
    }

    // Langsam zum Ziel „einklinken“
    while (current != finalNumber) {
      if (!mounted) return;
      await _superBallController.forward(from: 0);
      setState(() {
        current = (current + 1) % 10;
        _scheinSuperzahl = current;
      });
      await Future.delayed(Duration(milliseconds: delay));
      delay += 20;
    }

    if (!mounted) return;
    setState(() {
      _scheinSuperzahl = finalNumber;
      _superzahlGenerated = true;
      _isSuperBallSpinning = false;
    });

    _playSuperzahlSpinEnd();
    _startSuperzahlBlink();
  }

  void _startSuperzahlBlink() {
    int count = 0;
    const int maxToggles = 10; // 10 Toggles = 5x Blinken

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _isSuperzahlBlinkOn = !_isSuperzahlBlinkOn;
      });
      count++;
      if (count >= maxToggles) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isSuperzahlBlinkOn = false;
          });
        }
      }
    });
  }

  void _onSuperzahlTap() {
    if (_isSuperBallSpinning) return;

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
                      _isSuperzahlBlinkOn = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? _lottoYellow : Colors.blue.shade100,
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
    return AnimatedBuilder(
      animation: _superBallController,
      builder: (context, child) {
        final double angle = _isSuperBallSpinning
            ? _superBallController.value * 2 * pi
            : 0.0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _lottoYellow,
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(1, 2),
                  color: Colors.black26,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _scheinSuperzahl.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuperzahlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lottoRed, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titelzeile + Sound-Icon
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Schein-Superzahl',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _soundEnabled = !_soundEnabled;
                  });
                },
                icon: Icon(
                  _soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Leiste + Kugel + Button
          Row(
            children: [
              // Superzahl-Leiste 0–9
              Expanded(
                child: GestureDetector(
                  onTap: _onSuperzahlTap,
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
                        final bool blink =
                            isSelected && _isSuperzahlBlinkOn;
                        final Color bgColor = blink
                            ? Colors.white
                            : (isSelected ? _lottoYellow : Colors.blue.shade100);
                        final Color borderColor =
                            blink ? _lottoRed : _lottoRed;
                        return Container(
                          width: 36,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: borderColor, width: 1.0),
                          ),
                          child: Center(
                            child: Text(
                              index.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Kugel + Start-Button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSuperzahlBall(),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 26,
                    child: ElevatedButton(
                      onPressed:
                          _isSuperBallSpinning ? null : _runSuperzahlAnimation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSuperBallSpinning
                            ? Colors.grey[700]
                            : Colors.green[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _isSuperBallSpinning ? 'LÄUFT' : 'START',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _superzahlGenerated
                ? 'Aktuelle Superzahl: $_scheinSuperzahl'
                : _isSuperBallSpinning
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
      _isSuperzahlBlinkOn = false;
    });
  }

  // ----------------------------------------------------------
  // Tipp generieren (mit Favoriten, Snake-ähnliches Lauflicht)
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
    bool firstStep = true;

    _playSnakeStartSound();

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
              _playSnakeEatSound();
            }
          }
        });

        if (current >= maxNumber) {
          timer.cancel();
          _playSnakeEndSound();
          setState(() {
            _isAnimatingTip[tip] = false;
            _currentHighlight[tip] = null;
          });
        } else {
          current++;
        }

        if (firstStep) {
          firstStep = false;
        }
      },
    );
  }

  Future<void> _generateTip(int tip) async {
    if (_isAnimatingTip[tip] || _isGeneratingAll) return;
    await _runTipAnimation(tip);
  }

  Future<void> _generateAllTips() async {
    if (_isGeneratingAll) return;

    setState(() {
      _isGeneratingAll = true;
    });

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
        // Neue Zahl als Favorit, aber max. 6 insgesamt
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
                // Snake / Lauflicht über nicht finale Felder
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
        actions: [
          IconButton(
            icon: Icon(
              _soundEnabled ? Icons.volume_up : Icons.volume_off,
            ),
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
              });
            },
          ),
        ],
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
                  // Erhöht, damit 7×7-Grid + Zahlenzeile NICHT abgeschnitten wird
                  mainAxisExtent: isPortrait ? 340 : 270,
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

