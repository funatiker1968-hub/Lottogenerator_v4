import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'core_colors.dart';
import 'core_dimensions.dart';
import 'core/core_sounds.dart';

/// Lotto 6aus49 – modularer Screen
/// - 12 Tippfelder
/// - Superzahl-Kugel (größer, plastischer, Drehung + Tick-Sound)
/// - 7×7 Grid komplett sichtbar
/// - Favoriten-Logik (manuelle Zahlen bleiben bei „Alle generieren“ erhalten)
/// - Snake-ähnliches Lauflicht über das Zahlenfeld
/// - Ergebnisleiste unter dem Tipp
/// - Taskleiste unten mit Mute + „Alle generieren“ / „Alles löschen“
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

  /// Favoriten je Tipp (manuell gewählte Zahlen)
  final List<Set<int>> _favorites =
      List.generate(tipCount, (_) => <int>{});

  /// Generierte Zahlen je Tipp
  final List<Set<int>> _generated =
      List.generate(tipCount, (_) => <int>{});

  /// Aktuell gehighlightete Zahl pro Tipp (Lauflicht)
  final List<int?> _highlight = List<int?>.filled(tipCount, null);

  /// Läuft gerade eine Animation in diesem Tipp?
  final List<bool> _isAnimating = List<bool>.filled(tipCount, false);

  /// Timer je Tipp für das Lauflicht
  final List<Timer?> _timers = List<Timer?>.filled(tipCount, null);

  /// Superzahl-Zustände
  int _superNumber = 0;
  bool _superGenerated = false;
  bool _superRunning = false;

  /// Globaler Zustand für „Alle generieren“
  bool _allRunning = false;

  /// Globaler Mute
  bool _mute = false;

  /// Animation für die Superzahl-Kugel (Rotation + leichtes „Bouncen“)
  late final AnimationController _ballSpinController;
  late final Animation<double> _ballSpinAnimation;
  late final AnimationController _ballScaleController;
  late final Animation<double> _ballScaleAnimation;

  @override
  void initState() {
    super.initState();

    _ballSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _ballSpinAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ballSpinController,
      curve: Curves.easeOutQuad,
    ));

    _ballScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _ballScaleAnimation =
        Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(
      parent: _ballScaleController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t?.cancel();
    }
    _ballSpinController.dispose();
    _ballScaleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  //  GENERIERLOGIK
  // ---------------------------------------------------------------------------

  /// Erzeugt einen Tipp mit 6 Zahlen, Favoriten werden bevorzugt übernommen.
  Set<int> _makeTip(Set<int> favorites) {
    final Set<int> result = {...favorites};
    final List<int> pool =
        List<int>.generate(maxNumber, (i) => i + 1)..removeWhere(result.contains);

    while (result.length < numbersPerTip && pool.isNotEmpty) {
      final idx = _rnd.nextInt(pool.length);
      result.add(pool.removeAt(idx));
    }

    return result;
  }

  void _clearTip(int index) {
    _timers[index]?.cancel();
    _timers[index] = null;

    setState(() {
      _generated[index].clear();
      _highlight[index] = null;
      _isAnimating[index] = false;
      // Favoriten bleiben erhalten
    });
  }

  void _clearAll() {
    for (int i = 0; i < tipCount; i++) {
      _clearTip(i);
      _favorites[i].clear();
    }
    setState(() {
      _superNumber = 0;
      _superGenerated = false;
    });
  }

  void _toggleFavorite(int tipIndex, int number) {
    if (_isAnimating[tipIndex]) return;

    final fav = _favorites[tipIndex];

    setState(() {
      if (fav.contains(number)) {
        fav.remove(number);
      } else {
        // Maximal 6 Favoriten, sonst nichts mehr
        if (fav.length < numbersPerTip) {
          fav.add(number);
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  //  SUPERZAHL – Animation
  // ---------------------------------------------------------------------------

  Future<void> _runSuperAnimation() async {
    if (_superRunning) return;

    setState(() {
      _superRunning = true;
      _superGenerated = false;
    });

    final int target = _rnd.nextInt(10);
    int current = _superNumber;

    // Zwei schnelle Runden
    for (int round = 0; round < 2; round++) {
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;
        current = (current + 1) % 10;
        setState(() => _superNumber = current);
        if (!_mute) {
          LGSounds.playSpinFast();
        }
        _ballSpinController.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 60));
      }
    }

    // Langsames Einrasten auf die Zielzahl
    while (current != target) {
      if (!mounted) return;
      current = (current + 1) % 10;
      setState(() => _superNumber = current);
      if (!_mute) {
        LGSounds.playSpinSlow();
      }
      _ballSpinController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted) return;
    setState(() {
      _superNumber = target;
      _superRunning = false;
      _superGenerated = true;
    });

    // kleines „Bounce“ nach dem Einrasten
    _ballScaleController
      ..reset()
      ..forward();
  }

  // ---------------------------------------------------------------------------
  //  TIPP-ANIMATION (Snake-ähnliches Lauflicht)
  // ---------------------------------------------------------------------------

  Future<void> _startTipAnimation(int index) async {
    if (_isAnimating[index]) return;

    final Set<int> fav = _favorites[index];
    final Set<int> finalNumbers = _makeTip(fav);

    _timers[index]?.cancel();

    setState(() {
      _isAnimating[index] = true;
      _highlight[index] = 1;
    });

    int current = 1;

    _timers[index] = Timer.periodic(
      const Duration(milliseconds: 70),
      (Timer t) {
        if (!mounted) {
          t.cancel();
          return;
        }

        setState(() {
          _highlight[index] = current;
        });

        if (!_mute && finalNumbers.contains(current)) {
          LGSounds.playSnakeEat();
        }

        if (current >= maxNumber) {
          t.cancel();
          setState(() {
            _generated[index]
              ..clear()
              ..addAll(finalNumbers);
            _highlight[index] = null;
            _isAnimating[index] = false;
          });
          if (!_mute) {
            LGSounds.playSnakeOut();
          }
        } else {
          current++;
        }
      },
    );
  }

  Future<void> _generateOne(int index) async {
    if (_isAnimating[index]) return;

    if (!_superGenerated) {
      await _runSuperAnimation();
      if (!mounted) return;
    }

    await _startTipAnimation(index);
  }

  Future<void> _generateAll() async {
    if (_allRunning) return;

    setState(() => _allRunning = true);

    if (!_superGenerated) {
      await _runSuperAnimation();
      if (!mounted) {
        setState(() => _allRunning = false);
        return;
      }
    }

    for (int i = 0; i < tipCount; i++) {
      await _startTipAnimation(i);
      if (!mounted) {
        setState(() => _allRunning = false);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() => _allRunning = false);
  }

  // ---------------------------------------------------------------------------
  //  UI – Superzahl-Bereich
  // ---------------------------------------------------------------------------

  Widget _buildSuperRow() {
    return Container(
      height: LottoDim.superRowHeight(context),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLottoRed, width: 1.4),
      ),
      child: Row(
        children: [
          // Kugel
          SizedBox(
            width: LottoDim.superBallSize,
            height: LottoDim.superBallSize,
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_ballSpinController, _ballScaleController]),
              builder: (context, child) {
                final double scale = _ballScaleAnimation.value;
                final double turns = _ballSpinAnimation.value;
                return Transform.rotate(
                  angle: turns * 6.28318,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kLottoYellow,
                            kLottoYellow.withOpacity(0.8),
                            Colors.orange[200]!,
                          ],
                          center: const Alignment(-0.3, -0.3),
                          radius: 0.9,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(2, 4),
                          ),
                        ],
                        border: Border.all(color: kLottoRed, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          _superNumber.toString(),
                          style: TextStyle(
                            fontSize: LottoDim.superBallFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: LottoDim.superRowSpacing),

          // Leiste 0–9
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kLottoRed, width: 1.2),
              ),
              child: GridView.builder(
                itemCount: 10,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  final bool isSel = _superNumber == i;
                  return Container(
                    decoration: BoxDecoration(
                      color: isSel ? kLottoYellow : Colors.blue[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kLottoRed),
                    ),
                    child: Center(
                      child: Text(
                        i.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSel ? kLottoRed : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: LottoDim.superRowSpacing),

          // Start / Läuft-Button
          SizedBox(
            width: 80,
            height: 40,
            child: ElevatedButton(
              onPressed: _superRunning ? null : _runSuperAnimation,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _superRunning ? Colors.grey[500] : Colors.green[700],
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _superRunning ? 'Läuft' : 'Start',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  UI – Ergebnisleiste unter Tippkarte
  // ---------------------------------------------------------------------------

  Widget _buildResultRow(int index) {
    final Set<int> fin = _generated[index];
    if (fin.isEmpty) {
      return const SizedBox(height: 40);
    }

    final List<int> sorted = fin.toList()..sort();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.yellow[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLottoRed),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: kHitGreen,
              shape: BoxShape.circle,
              border: Border.all(color: kLottoRed, width: 1.2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sorted.map((n) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kLottoRed, width: 1),
                  ),
                  child: Text(
                    n.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: kHitGreen,
              shape: BoxShape.circle,
              border: Border.all(color: kLottoRed, width: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  UI – Tippkarte
  // ---------------------------------------------------------------------------

  Widget _buildTipCard(int index) {
    final fav = _favorites[index];
    final gen = _generated[index];
    final hl = _highlight[index];
    final run = _isAnimating[index];
    final has = gen.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.yellow[600],
        borderRadius: BorderRadius.circular(LottoDim.tipCardRadius),
        border: Border.all(color: Colors.orange[800]!, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopfzeile
          Row(
            children: [
              Text(
                'Tipp ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: run
                    ? null
                    : has
                        ? () => _clearTip(index)
                        : () => _generateOne(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: run
                      ? Colors.grey[500]
                      : has
                          ? Colors.red[700]
                          : Colors.green[700],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  run
                      ? 'Läuft...'
                      : has
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

          // Zahlenraster 7×7
          AspectRatio(
            aspectRatio: LottoDim.gridColumns / 6,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: LottoDim.gridColumns,
                crossAxisSpacing: LottoDim.gridSpacing,
                mainAxisSpacing: LottoDim.gridSpacing,
                childAspectRatio: LottoDim.gridAspectRatio,
              ),
              itemCount: maxNumber,
              itemBuilder: (context, idx) {
                final number = idx + 1;
                final bool isFav = fav.contains(number);
                final bool isGen = gen.contains(number);
                final bool isHL = hl == number;

                Color bg;
                Color border = kLottoRed;
                Widget inner;

                if (isHL && !isGen && !isFav) {
                  // Lauflicht – nur Highlight
                  bg = kLottoYellow;
                  inner = Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                } else if (isFav && isGen) {
                  // Treffer + Favorit
                  bg = kHitGreenLight;
                  border = kHitGreen;
                  inner = Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                } else if (isFav && !isGen) {
                  // Nur Favorit (noch nicht gezogen)
                  bg = Colors.white;
                  border = Colors.blueGrey;
                  inner = Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                } else if (!isFav && isGen) {
                  // Nur generiert
                  bg = kLottoGrey;
                  inner = Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                } else {
                  // Neutral
                  bg = kLottoGrey;
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
                  onTap: () => _toggleFavorite(index, number),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: border, width: 0.7),
                    ),
                    child: Center(child: inner),
                  ),
                );
              },
            ),
          ),

          _buildResultRow(index),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  UI – Untere Taskleiste
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    return Container(
      height: LottoDim.taskbarHeight(context),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: LottoDim.taskbarIconSize,
            icon: Icon(
              _mute ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _mute = !_mute);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _allRunning ? null : _generateAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _allRunning
                          ? Colors.grey[400]
                          : Colors.greenAccent,
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      _allRunning ? 'Läuft...' : 'Alle generieren',
                      style: const TextStyle(
                        color: Colors.black,
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
                      backgroundColor: Colors.redAccent,
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
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
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final bool isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto 6aus49'),
        backgroundColor: kLottoRed,
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildSuperRow(),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: isPortrait ? 2 : 3,
                childAspectRatio: isPortrait ? 0.78 : 0.95,
                children: List.generate(
                  tipCount,
                  (i) => _buildTipCard(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
