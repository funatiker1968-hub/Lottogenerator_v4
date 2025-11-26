import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'core_colors.dart';
import 'core_dimensions.dart';
import 'core/core_sounds.dart';

/// Lotto 6aus49 – modularer Screen
/// Verbesserte Version mit:
/// • Superzahl-Lauflicht (langsamer Auslauf + Blinkphase)
/// • Horizontale Animation in der Superzahl-Kugel
/// • 7×7 Grid komplett sichtbar
/// • Snake-Animation erweitert (Bissspuren + Pulsieren)
/// • Sequenzielle Tippgenerierung
/// • Neue Sounds aus assets/sounds

class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen>
    with TickerProviderStateMixin {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int numbersPerTip = 6;

  final Random _rnd = Random();

  /// Favoriten je Tipp
  final List<Set<int>> _favorites =
      List.generate(tipCount, (_) => <int>{});

  /// Generierte Zahlen je Tipp
  final List<Set<int>> _generated =
      List.generate(tipCount, (_) => <int>{});

  /// Lauflicht-Highlight (für Snake-Effekt)
  final List<int?> _highlight = List<int?>.filled(tipCount, null);

  /// Animationsstatus je Tipp
  final List<bool> _isAnimating = List<bool>.filled(tipCount, false);

  /// Timer je Tipp (für Snake-Lauflicht)
  final List<Timer?> _timers = List<Timer?>.filled(tipCount, null);

  /// Superzahl (final)
  int _superNumber = 0;

  /// aktuell gehighlightete Superzahl
  int? _superHighlight;

  /// Animation Superzahl läuft?
  bool _superRunning = false;

  /// globaler Status für „Alle generieren“
  bool _allRunning = false;

  /// Sound stumm?
  bool _mute = false;

  /// Bissmarkierungen für Snake-Effekt
  final List<bool> _bitten = List<bool>.filled(maxNumber + 1, false);

  /// Pulsieren nach Snake-Ende
  bool _pulse = false;

  // --------------------------------------------------------------
  // Superzahl – Hauptanimation (MIT verbessertem Lauflicht)
  // --------------------------------------------------------------
  Future<void> startSuperNumber() async {
    if (_superRunning) return;

    _superRunning = true;
    if (!_mute) LGSounds.playSpinFast();

    // Runde 1–3 schnell, Runde 4 verlangsamt
    for (int round = 1; round <= 4; round++) {
      for (int i = 0; i < 10; i++) {
        setState(() => _superHighlight = i);

        // in letzter Runde auf Zielzahl stoppen
        if (round == 4 && i == _superNumber) break;

        final delay = round < 3
            ? 100
            : 100 + 50 * i; // Runde 4 → langsamer

        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    if (!_mute) LGSounds.playSpinSlow();

    // Finales Blinken
    for (int j = 0; j < 5; j++) {
      setState(() => _superHighlight = null);
      await Future.delayed(const Duration(milliseconds: 200));

      setState(() => _superHighlight = _superNumber);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _superRunning = false;
  }

  // --------------------------------------------------------------
  // Superzahl – Kugel mit horizontal animierter Ziffer
  // --------------------------------------------------------------
  Widget _buildSuperBall() {
    return SizedBox(
      width: LottoDim.superBallSize,
      height: LottoDim.superBallSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kugel
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.yellow[600],
              border: Border.all(color: kLottoRed, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ],
            ),
          ),

          // animierte Ziffer (links → rechts)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuad,
            left:  ((_superHighlight ?? _superNumber) * 3).toDouble(),
            child: Text(_superNumber.toString(),
            style: const TextStyle(fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
// --------------------------------------------------------------
  // Tippkarten – Generator für EINEN Tipp (6 Zahlen)
  // --------------------------------------------------------------
  Future<void> _generateTip(int index) async {
    if (_isAnimating[index]) return;

    _generated[index].clear();
    _bitten.fillRange(0, _bitten.length, false);

    _isAnimating[index] = true;

    // Snake-Effekt: Highlight wandert durch alle Zahlen
    int pos = 1;
    _timers[index]?.cancel();
    _timers[index] = Timer.periodic(
      const Duration(milliseconds: 60),
      (timer) {
        if (!mounted) return;

        setState(() {
          _highlight[index] = pos;
        });

        pos++;
        if (pos > maxNumber) pos = 1;
      },
    );

    // kurze Laufzeit, dann stoppen
    await Future.delayed(const Duration(milliseconds: 800));

    _timers[index]?.cancel();

    // Generiere genau 6 eindeutige Zahlen
    final Set<int> result = {};
    while (result.length < numbersPerTip) {
      int n = _rnd.nextInt(maxNumber) + 1;
      result.add(n);
    }

    // Beim Setzen: Biss-Effekt aktivieren
    for (final n in result) {
      _bitten[n] = true;
      if (!_mute) LGSounds.playSnakeEat();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      _generated[index] = result;
      _highlight[index] = null;
    });

    // Nach der Snake → Pulsierung
    for (int k = 0; k < 3; k++) {
      setState(() => _pulse = true);
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _pulse = false);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _isAnimating[index] = false;
  }

  // --------------------------------------------------------------
  // ALLE Tipps nacheinander generieren (NEU)
  // --------------------------------------------------------------
  Future<void> _generateAll() async {
    if (_allRunning) return;

    setState(() => _allRunning = true);

    for (int i = 0; i < tipCount; i++) {
      await _generateTip(i);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _allRunning = false);
  }

  // --------------------------------------------------------------
  // Tipp zurücksetzen
  // --------------------------------------------------------------
  void _clearTip(int index) {
    _timers[index]?.cancel();
    setState(() {
      _highlight[index] = null;
      _generated[index].clear();
      _favorites[index].clear();
    });
  }

  // --------------------------------------------------------------
  // ALLES löschen
  // --------------------------------------------------------------
  void _clearAll() {
    for (int i = 0; i < tipCount; i++) {
      _clearTip(i);
    }
  }

  // --------------------------------------------------------------
  // Build – Hauptaufbau
  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kLottoYellow,
        title: const Text(
          'Lotto 6aus49',
          style: TextStyle(
            color: kLottoRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _mute = !_mute);
            },
            icon: Icon(
              _mute ? Icons.volume_off : Icons.volume_up,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Superzahl-Bereich
          _buildSuperRow(),

          const SizedBox(height: 10),

          // Tippkarten-Bereich
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: tipCount,
              itemBuilder: (context, i) => _buildTipCard(i),
            ),
          ),

          _buildTaskBar(context),
        ],
      ),
    );
  }
// --------------------------------------------------------------
  // Superzahl – Zeile mit Kugel und Zahlenleiste
  // --------------------------------------------------------------
  Widget _buildSuperRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildSuperBall(),
          const SizedBox(width: 12),

          // Leiste 0–9
          Expanded(
            child: SizedBox(
              height: LottoDim.superBallSize * 0.65,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: 10,
                itemBuilder: (context, i) {
                  final isHighlight = i == _superHighlight;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isHighlight
                          ? Colors.redAccent
                          : Colors.yellow[600],
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.red.shade900, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        i.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isHighlight ? Colors.white : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Superzahl starten
          ElevatedButton(
            onPressed: _superRunning ? null : startSuperNumber,
            style: ElevatedButton.styleFrom(
              backgroundColor: kLottoRed,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Lauf!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Tippkarte
  // --------------------------------------------------------------
  Widget _buildTipCard(int index) {
    final fav = _favorites[index];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.yellow[600],
        borderRadius: BorderRadius.circular(LottoDim.tipCardRadius),
        border: Border.all(color: Colors.orange[800]!, width: 1),
      ),
      child: Column(
        children: [
          // Titel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tipp ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Row(
                children: [
                  // Favoriten löschen
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() => fav.clear());
                    },
                    icon: const Icon(Icons.favorite_border,
                        color: Colors.red),
                  ),
                  // Tipp löschen
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _clearTip(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),

          // Grid 1–49
          AspectRatio(
            aspectRatio: 7 / 6.2, // angepasst für komplette Sichtbarkeit
            child: _buildNumberGrid(index),
          ),

          const SizedBox(height: 4),

          // Buttons Tipp generieren
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _isAnimating[index]
                    ? null
                    : () => _generateTip(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLottoRed,
                ),
                child: const Text(
                  'Generieren',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _clearTip(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text(
                  'Löschen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
// --------------------------------------------------------------
  // GRID 1–49 (mit Highlight, Bissspuren und Pulsieren)
  // --------------------------------------------------------------
  Widget _buildNumberGrid(int index) {
    final generated = _generated[index];
    final highlight = _highlight[index];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: LottoDim.gridColumns,
        crossAxisSpacing: LottoDim.gridSpacing,
        mainAxisSpacing: LottoDim.gridSpacing,
        childAspectRatio: LottoDim.gridAspectRatio,
      ),
      itemCount: maxNumber,
      itemBuilder: (context, i) {
        final number = i + 1;
        final isGenerated = generated.contains(number);
        final isFav = _favorites[index].contains(number);
        final isHighlight = highlight == number;

        final wasBitten = _bitten[number];
        final pulse = wasBitten && _pulse;

        Color bg = Colors.white;
        Color border = Colors.grey.shade400;

        // generierte Zahlen gelb
        if (isGenerated) {
          bg = Colors.yellow.shade300;
          border = Colors.orange.shade600;
        }

        // Favoriten rot umrandet
        if (isFav) {
          border = Colors.red.shade700;
        }

        // Snake-Lauflicht Highlight
        if (isHighlight) {
          bg = Colors.redAccent;
          border = Colors.red.shade900;
        }

        // Bissspuren + Pulsieren
        if (pulse) {
          bg = Colors.red.shade100.withOpacity(0.6);
          border = Colors.red.shade700;
        } else if (wasBitten) {
          bg = Colors.red.shade50.withOpacity(0.7);
          border = Colors.red.shade400;
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_favorites[index].contains(number)) {
                _favorites[index].remove(number);
              } else {
                _favorites[index].add(number);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isGenerated ? FontWeight.bold : FontWeight.normal,
                  color: isHighlight ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------
  // Untere Bedienleiste (TASK BAR)
  // --------------------------------------------------------------
  Widget _buildTaskBar(BuildContext context) {
      return Container(
      height: LottoDim.taskbarHeight(context),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.yellow,
        border: Border(
          top: BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ALLE generieren
          ElevatedButton(
            onPressed: _allRunning ? null : _generateAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: kLottoRed,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Alle generieren',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),

          // ALLES löschen
          ElevatedButton(
            onPressed: _clearAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Alle löschen',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
// --------------------------------------------------------------
// Farben & Styles – falls benötigt, hier Referenz
// --------------------------------------------------------------

// In core_colors.dart definiert:
// const Color kLottoRed = Color(0xFFD40000);
// const Color kLottoYellow = Color(0xFFFFEB3B);
// const Color kBackground = Color(0xFFFFFDE7);

// --------------------------------------------------------------
// Dimensionen – Referenz aus core_dimensions.dart
// --------------------------------------------------------------

/*
class LottoDim {
  static const int gridColumns = 7;
  static const double gridSpacing = 1.0;
  static const double gridAspectRatio = 0.82;

  static const double tipCardRadius = 12.0;

  static const double superBallSize = 100;  // erhöhte Größe

  static const double taskbarHeight = 64.0;
}
*/

// --------------------------------------------------------------
// SOUNDS – Referenz (assets/sounds/...)
// --------------------------------------------------------------

/*
class LGSounds {
  static void playSpinFast();
  static void playSpinSlow();
  static void playSnakeEat();
  static void playSnakeExit();
}
*/

// --------------------------------------------------------------
// Ende der Datei
// --------------------------------------------------------------


