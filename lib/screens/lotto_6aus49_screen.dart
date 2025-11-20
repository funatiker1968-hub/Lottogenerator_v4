import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../core/lg_sounds.dart';

/// Lotto 6aus49 – FINAL VERSION
/// - 12 Tippfelder mit Snake-Lauflicht
/// - Favoriten bleiben beim Generieren erhalten
/// - Generierte Zahlen + Favoriten nachträglich änderbar
/// - Superzahl-Kugel (80×80) links, 0–9-Leiste mittig, Start-Button rechts
/// - Fixe Taskleiste unten mit Mute + „Alle generieren“ / „Alles löschen“
/// - Snake-Bar unter jedem Tipp nach Lauf (Kopf/Schwanz grün, Zahlenkörper gelb)

const Color _lottoYellow = Color(0xFFFFDD00);
const Color _lottoRed = Color(0xFFD20000);
const Color _lottoGrey = Color(0xFFF2F2F2);

const Color _hitGreen = Color(0xFF2E7D32);
const Color _hitGreenLt = Color(0xFF4CAF50);

const Color _snakeHead = Color(0xFF4CAF50); // Blattgrün
const Color _snakeTail = Color(0xFF4CAF50);
const Color _snakeBody = Color(0xFFFFF8C0); // hellgelb für Zahlen

const Color _generatedBlue = Color(0xFFBEE6FF); // Hintergrund generierte Zahlen im Grid

class Lotto6aus49Screen extends StatefulWidget {
  const Lotto6aus49Screen({super.key});

  @override
  State<Lotto6aus49Screen> createState() => _Lotto6aus49ScreenState();
}

class _Lotto6aus49ScreenState extends State<Lotto6aus49Screen>
    with SingleTickerProviderStateMixin {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int perTip = 6;

  final Random _rnd = Random();

  /// Manuelle Favoriten (werden beim Generieren NIE überschrieben)
  final List<List<bool>> _favorites =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Generierte Zahlen
  final List<List<bool>> _generated =
      List.generate(tipCount, (_) => List.filled(maxNumber, false));

  /// Highlight (Snake-Kopf) pro Tipp
  final List<int?> _highlight = List<int?>.filled(tipCount, null);

  /// Läuft gerade die Snake-Animation in diesem Tipp?
  final List<bool> _isAnimating = List<bool>.filled(tipCount, false);

  /// Timer pro Tipp
  final List<Timer?> _tipTimers = List<Timer?>.filled(tipCount, null);

  /// Superzahl-Zustand
  int _super = 0;
  bool _superGenerated = false;
  bool _superRunning = false;
  bool _superBlinkOn = false;

  /// Globaler Zustand
  bool _allRunning = false;
  bool _mute = false;

  /// Snake-Darstellung nach dem Lauf
  final List<List<int>> _snakeBodyPerTip =
      List.generate(tipCount, (_) => <int>[]);
  final List<bool> _snakeExited =
      List<bool>.filled(tipCount, false);
  final List<bool> _snakeBlinkOn =
      List<bool>.filled(tipCount, false);

  @override
  void dispose() {
    for (final t in _tipTimers) {
      t?.cancel();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _tipHasAnything(int tip) {
    for (int i = 0; i < maxNumber; i++) {
      if (_favorites[tip][i] || _generated[tip][i]) return true;
    }
    return false;
  }

  int _countSelected(int tip) {
    int c = 0;
    for (int i = 0; i < maxNumber; i++) {
      if (_favorites[tip][i] || _generated[tip][i]) c++;
    }
    return c;
  }

  // ---------------------------------------------------------------------------
  // Superzahl
  // ---------------------------------------------------------------------------

  Future<void> _runSuperAnimation() async {
    if (_superRunning) return;

    setState(() {
      _superRunning = true;
      _superGenerated = false;
      _superBlinkOn = false;
    });

    final int target = _rnd.nextInt(10);

    // 2 schnelle Runden
    for (int r = 0; r < 2; r++) {
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;
        setState(() {
          _super = i;
        });
        if (!_mute) LGSounds.playSpinStart();
        await Future.delayed(const Duration(milliseconds: 70));
      }
    }

    // letzte langsamere Runde bis Ziel
    for (int i = 0; i <= target; i++) {
      if (!mounted) return;
      setState(() {
        _super = i;
      });
      if (!_mute) LGSounds.playSpinEnd();
      await Future.delayed(const Duration(milliseconds: 140));
    }

    if (!mounted) return;
    setState(() {
      _super = target;
      _superGenerated = true;
      _superRunning = false;
    });

    _startSuperBlink();
  }

  void _startSuperBlink() {
    int count = 0;
    const int maxToggles = 10;

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _superBlinkOn = !_superBlinkOn;
      });
      count++;
      if (count >= maxToggles) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _superBlinkOn = false;
          });
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Snake / Tipp-Generierung
  // ---------------------------------------------------------------------------

  List<int> _buildFinalSetForTip(int tip) {
    final List<int> favs = [];
    for (int i = 0; i < maxNumber; i++) {
      if (_favorites[tip][i]) favs.add(i + 1);
    }

    int need = perTip - favs.length;
    if (need < 0) need = 0;

    final List<int> pool = [
      for (int n = 1; n <= maxNumber; n++)
        if (!favs.contains(n)) n,
    ];
    pool.shuffle(_rnd);

    final List<int> newGen = pool.take(need).toList();
    final List<int> all = [...favs, ...newGen]..sort();
    return all;
  }

  void _clearTip(int tip) {
    _tipTimers[tip]?.cancel();
    _tipTimers[tip] = null;

    setState(() {
      for (int i = 0; i < maxNumber; i++) {
        _favorites[tip][i] = false;
        _generated[tip][i] = false;
      }
      _highlight[tip] = null;
      _isAnimating[tip] = false;
      _snakeBodyPerTip[tip].clear();
      _snakeExited[tip] = false;
      _snakeBlinkOn[tip] = false;
    });
  }

  void _clearAll() {
    for (int t = 0; t < tipCount; t++) {
      _clearTip(t);
    }
    setState(() {
      _super = 0;
      _superGenerated = false;
      _superBlinkOn = false;
    });
  }

  Future<void> _runTip(int tip) async {
    _tipTimers[tip]?.cancel();
    _tipTimers[tip] = null;

    final List<int> finalSet = _buildFinalSetForTip(tip);
    final List<int> favs = [];
    final List<int> gens = [];

    for (final n in finalSet) {
      if (_favorites[tip][n - 1]) {
        favs.add(n);
      } else {
        gens.add(n);
      }
    }

    setState(() {
      // Generierte Zahlen zurücksetzen, Favoriten bleiben
      for (int i = 0; i < maxNumber; i++) {
        _generated[tip][i] = false;
      }
      _highlight[tip] = null;
      _isAnimating[tip] = true;
      _snakeExited[tip] = false;
      _snakeBlinkOn[tip] = false;

      // Snake-Körper: alle finalen Zahlen (Favoriten + Generierte), sortiert
      _snakeBodyPerTip[tip]
        ..clear()
        ..addAll(finalSet);
    });

    if (!_mute) LGSounds.playSnakeStart();

    int cur = 1;
    _tipTimers[tip] = Timer.periodic(
      const Duration(milliseconds: 70),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }

        setState(() {
          _highlight[tip] = cur;

          if (finalSet.contains(cur)) {
            if (favs.contains(cur)) {
              _favorites[tip][cur - 1] = true;
            } else {
              _generated[tip][cur - 1] = true;
              if (!_mute) LGSounds.playSnakeEat();
            }
          }
        });

        if (cur >= maxNumber) {
          t.cancel();
          if (!_mute) LGSounds.playSnakeEnd();
          setState(() {
            _isAnimating[tip] = false;
            _highlight[tip] = null;
            _snakeExited[tip] = true;
          });
          _startSnakeParkAnimation(tip);
        } else {
          cur++;
        }
      },
    );
  }

  void _startSnakeParkAnimation(int tip) {
    int count = 0;
    const int maxToggles = 12;

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !_snakeExited[tip]) {
        timer.cancel();
        return;
      }
      setState(() {
        _snakeBlinkOn[tip] = !_snakeBlinkOn[tip];
      });
      count++;
      if (count >= maxToggles) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _snakeBlinkOn[tip] = false;
          });
        }
      }
    });
  }

  Future<void> _generateOne(int tip) async {
    if (_isAnimating[tip]) return;

    if (!_superGenerated) {
      await _runSuperAnimation();
      if (!mounted) return;
    }

    await _runTip(tip);
  }

  Future<void> _generateAll() async {
    if (_allRunning) return;

    setState(() {
      _allRunning = true;
    });

    if (!_superGenerated) {
      await _runSuperAnimation();
      if (!mounted) {
        _allRunning = false;
        return;
      }
    }

    for (int t = 0; t < tipCount; t++) {
      await _runTip(t);
      if (!mounted) {
        _allRunning = false;
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() {
      _allRunning = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Manuelles Togglen (Favoriten / generierte Zahlen nachträglich ändern)
  // ---------------------------------------------------------------------------

  void _toggleNumber(int tip, int index) {
    if (_isAnimating[tip] || _allRunning) return;

    setState(() {
      final bool isFav = _favorites[tip][index];
      final bool isGen = _generated[tip][index];

      // Aktuelle Gesamtanzahl
      int count = _countSelected(tip);

      if (!isFav && !isGen) {
        // neue Favoritenzahl, aber max. 6 insgesamt
        if (count >= perTip) return;
        _favorites[tip][index] = true;

        // Wenn Snake-Bar existiert, Zahl in Body aufnehmen
        final n = index + 1;
        if (!_snakeBodyPerTip[tip].contains(n)) {
          _snakeBodyPerTip[tip].add(n);
          _snakeBodyPerTip[tip].sort();
        }
      } else if (isFav && !isGen) {
        // Favorit löschen
        _favorites[tip][index] = false;
        final n = index + 1;
        _snakeBodyPerTip[tip].remove(n);
      } else if (!isFav && isGen) {
        // Generierte Zahl löschen
        _generated[tip][index] = false;
        final n = index + 1;
        _snakeBodyPerTip[tip].remove(n);
      } else {
        // beides true (theoretisch nicht nötig, aber zur Sicherheit)
        _favorites[tip][index] = false;
        _generated[tip][index] = false;
        final n = index + 1;
        _snakeBodyPerTip[tip].remove(n);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // UI: Superzahlzeile
  // ---------------------------------------------------------------------------

  Widget _buildSuperRow() {
    final double h = MediaQuery.of(context).size.height * 0.15;

    return Container(
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lottoRed, width: 1.4),
      ),
      child: Row(
        children: [
          // Superzahl-Kugel 80x80 links
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedRotation(
                  turns: _superRunning ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _lottoYellow,
                      border: Border.all(color: _lottoRed, width: 3),
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _superGenerated ? 1 : 0.3,
                        child: Text(
                          _super.toString(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Leiste 0–9 mittig
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _lottoRed, width: 1.2),
              ),
              child: GridView.builder(
                itemCount: 10,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  final bool isSel = _super == i;
                  final bool blink =
                      isSel && _superGenerated && _superBlinkOn;

                  final Color bg = blink
                      ? Colors.white
                      : (isSel ? _lottoYellow : Colors.blue[100]!);
                  final Color textColor =
                      blink ? _lottoRed : (isSel ? _lottoRed : Colors.black);

                  return Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _lottoRed),
                    ),
                    child: Center(
                      child: Text(
                        i.toString(),
                        style: TextStyle(
                          fontSize: 16,
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

          const SizedBox(width: 10),

          // Start-Button rechts
          SizedBox(
            width: 70,
            height: 40,
            child: ElevatedButton(
              onPressed: _superRunning ? null : _runSuperAnimation,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _superRunning ? Colors.grey[500] : Colors.green[700],
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
  // UI: Snake-Bar unter dem Tipp
  // ---------------------------------------------------------------------------

  Widget _buildSnakeBar(int tip) {
    final body = _snakeBodyPerTip[tip];
    if (!_snakeExited[tip] || body.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.yellow[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lottoRed),
      ),
      child: Row(
        children: [
          // Kopf (mit leichtem Fade über blink-Flag)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _snakeBlinkOn[tip] ? 0.6 : 1.0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _snakeHead,
                shape: BoxShape.circle,
                border: Border.all(color: _lottoRed, width: 1.2),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Körpersegmente mit Zahlen
          ...body.map((n) {
            final bool isFav = _favorites[tip][n - 1];
            final bool isGen = _generated[tip][n - 1];
            final Color textColor = isFav
                ? Colors.black
                : (isGen ? _lottoRed : Colors.black);

            final bool blink = _snakeBlinkOn[tip];

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: blink ? 0.6 : 1.0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _snakeBody,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _lottoRed),
                ),
                child: Text(
                  n.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(width: 6),

          // Schwanz
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _snakeBlinkOn[tip] ? 0.6 : 1.0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _snakeTail,
                shape: BoxShape.circle,
                border: Border.all(color: _lottoRed, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI: Zahlenliste unter dem Tipp (Favoriten schwarz, generierte rot)
  // ---------------------------------------------------------------------------

  Widget _buildResultRow(int tip) {
    if (_isAnimating[tip]) return const SizedBox.shrink();

    final List<int> nums = [];
    for (int i = 0; i < maxNumber; i++) {
      if (_favorites[tip][i] || _generated[tip][i]) {
        nums.add(i + 1);
      }
    }
    if (nums.isEmpty) return const SizedBox.shrink();
    nums.sort();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          const Text(
            'Zahlen:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...nums.map((n) {
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
    );
  }

  // ---------------------------------------------------------------------------
  // UI: Tippkarte mit Grid + Snake + ResultRow
  // ---------------------------------------------------------------------------

  Widget _buildTipCard(int tip) {
    final hl = _highlight[tip];
    final run = _isAnimating[tip];

    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.yellow[600],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[800]!, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopfzeile
          Row(
            children: [
              Text(
                'Tipp ${tip + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: run
                    ? null
                    : _tipHasAnything(tip)
                        ? () => _clearTip(tip)
                        : () => _generateOne(tip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: run
                      ? Colors.grey[500]
                      : _tipHasAnything(tip)
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
                      : _tipHasAnything(tip)
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

          // 7×7 Grid
          AspectRatio(
            aspectRatio: 7 / 6,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 1.5,
                mainAxisSpacing: 1.5,
                childAspectRatio: 0.9,
              ),
              itemCount: maxNumber,
              itemBuilder: (context, index) {
                final int number = index + 1;
                final bool isFav = _favorites[tip][index];
                final bool isGen = _generated[tip][index];
                final bool isFinal = isFav || isGen;
                final bool isHl = hl == number;

                Color bg;
                Color border = _lottoRed;
                Widget inner;

                if (isHl && !isFinal) {
                  // Snake-Kopf
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
                  // Finale Zahl (Favorit vs generiert)
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
                  // normale, nicht ausgewählte Zahl
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
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: border, width: 0.7),
                    ),
                    child: Center(child: inner),
                  ),
                );
              },
            ),
          ),

          // Snake-Bar + Zahlenliste
          _buildSnakeBar(tip),
          _buildResultRow(tip),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI: Taskleiste unten (Mute + Alle generieren / Alles löschen)
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _allRunning ? null : _generateAll,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _allRunning ? Colors.grey[400] : Colors.greenAccent,
              padding: const EdgeInsets.symmetric(vertical: 10),
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final bool isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto 6aus49'),
      ),
      bottomNavigationBar: Container(
        height: MediaQuery.of(context).size.height * 0.08,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border(
            top: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                _mute ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _mute = !_mute;
                });
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBottomButtons(),
            ),
          ],
        ),
      ),
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

