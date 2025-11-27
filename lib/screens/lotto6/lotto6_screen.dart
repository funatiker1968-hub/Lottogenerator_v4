import 'dart:math';
import 'package:flutter/material.dart';

import 'core_colors.dart';
import 'core_dimensions.dart';
import 'superzahl_area.dart';
import 'core_sounds.dart';

class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int numbersPerTip = 6;

  final Random _rng = Random();

  late List<Set<int>> _favorites;
  late List<List<int>> _generated;
  late List<int?> _highlight;
  late List<bool> _fixed;
  late List<bool> _finalBlink;

  bool _allRunning = false;
  bool _mute = false;

  @override
  void initState() {
    super.initState();
    _favorites = List.generate(tipCount, (_) => <int>{});
    _generated = List.generate(tipCount, (_) => <int>[]);
    _highlight = List.generate(tipCount, (_) => null);
    _fixed = List.generate(tipCount, (_) => false);
    _finalBlink = List.generate(tipCount, (_) => false);
    LGSounds.mute = false;
  }

  // ------------------------------------------------------------------
  // EINEN TIPP GENERIEREN
  // ------------------------------------------------------------------
  Future<void> _generateTip(int index) async {
    if (_fixed[index]) return;

    final favs = Set<int>.from(_favorites[index]);
    final result = Set<int>.from(favs);

    while (result.length < numbersPerTip) {
      result.add(1 + _rng.nextInt(maxNumber));
    }

    final sorted = result.toList()..sort();

    setState(() => _generated[index] = sorted);

    await _runHighlightForTip(index);
  }

  // Durchlauf 1..49 mit Highlight
  Future<void> _runHighlightForTip(int index) async {
    final nums = _generated[index];
    if (nums.isEmpty) return;

    for (int n = 1; n <= maxNumber; n++) {
      if (!mounted) return;

      setState(() => _highlight[index] = n);

      await LGSounds.playTick();

      if (nums.contains(n)) {
        await Future.delayed(const Duration(milliseconds: 120));
      } else {
        await Future.delayed(const Duration(milliseconds: 45));
      }
    }

    if (!mounted) return;
    setState(() => _highlight[index] = null);

    await _finalBlinkRow(index);
  }

  // Finale Blinksequenz der Kugel-Reihe
  Future<void> _finalBlinkRow(int index) async {
    if (_generated[index].isEmpty) return;

    for (int r = 0; r < 3; r++) {
      if (!mounted) return;
      setState(() => _finalBlink[index] = true);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _finalBlink[index] = false);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // ------------------------------------------------------------------
  // ALLE TIPPS GENERIEREN
  // ------------------------------------------------------------------
  Future<void> _generateAll() async {
    if (_allRunning) return;

    setState(() => _allRunning = true);
    for (int i = 0; i < tipCount; i++) {
      await _generateTip(i);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    setState(() => _allRunning = false);
  }

  // ------------------------------------------------------------------
  // EINEN TIPP LÖSCHEN / ALLE LÖSCHEN
  // ------------------------------------------------------------------
  void _clearTip(int index) {
    setState(() {
      _generated[index] = [];
      _highlight[index] = null;
      _favorites[index].clear();
      _fixed[index] = false;
      _finalBlink[index] = false;
    });
  }

  void _clearAll() {
    setState(() {
      for (int i = 0; i < tipCount; i++) {
        _generated[i] = [];
        _highlight[i] = null;
        _favorites[i].clear();
        _fixed[i] = false;
        _finalBlink[i] = false;
      }
    });
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final totalHeight = media.size.height;

    final double superHeight = totalHeight * 0.12;
    final double tipsHeight = totalHeight * 0.80;
    final double taskHeight = totalHeight * 0.08;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: superHeight,
              child: SuperzahlArea(height: superHeight),
            ),
            SizedBox(
              height: tipsHeight,
              child: _buildTipsArea(context),
            ),
            SizedBox(
              height: taskHeight,
              child: _buildTaskBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // TIPP-BEREICH (2 Spalten Hochformat, 3 Spalten Querformat)
  // ------------------------------------------------------------------
  Widget _buildTipsArea(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    final int columns = orientation == Orientation.portrait ? 2 : 3;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double spacing = 12.0;
        final double cardWidth =
            (totalWidth - (columns - 1) * spacing - 16) / columns;
        final double cardHeight = cardWidth * 1.9;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(tipCount, (index) {
                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _buildTipCard(index),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // EINZELNE TIPP-KARTE
  // ------------------------------------------------------------------
  Widget _buildTipCard(int index) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double totalH = constraints.maxHeight;

        const double titleH = 24;
        const double finalRowH = 32;
        const double buttonRowH = 36;
        const double paddingH = 16;

        final double gridH =
            totalH - titleH - finalRowH - buttonRowH - paddingH;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LottoDim.tipCardRadius),
            border: Border.all(color: kLottoGrey, width: 1),
          ),
          child: Column(
            children: [
              SizedBox(
                height: titleH,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tipp ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: gridH,
                child: _buildNumberGrid(index),
              ),
              SizedBox(
                height: finalRowH,
                child: _buildFinalRow(index),
              ),
              SizedBox(
                height: buttonRowH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed:
                          _allRunning ? null : () => _generateTip(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      child: const Text(
                        "Generieren",
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _clearTip(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      child: const Text(
                        "Löschen",
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  
  // ====================================================================
  // GRID 1..49 — 7×7 vollständig sichtbar
  // ====================================================================
  Widget _buildNumberGrid(int tipIndex) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Wir berechnen exakte Quadrate
        final double cellSize =
            (constraints.maxWidth - (LottoDim.gridColumns - 1) * 1.5) /
                LottoDim.gridColumns;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(4),
          itemCount: maxNumber,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: LottoDim.gridColumns,
            crossAxisSpacing: 1.5,
            mainAxisSpacing: 1.5,
            childAspectRatio: 1.0, // QUADRAT!
          ),
          itemBuilder: (context, i) {
            final number = i + 1;

            final fav = _favorites[tipIndex].contains(number);
            final gen = _generated[tipIndex].contains(number);
            final hi = _highlight[tipIndex] == number;

            Color bg = Colors.white;
            if (hi) bg = const Color(0xFFFFE4B5);

            Color border = kLottoGrey;
            if (gen) border = Colors.black;
            else if (fav) border = kLottoRed;

            Color textColor = Colors.black;
            if (fav && !gen) textColor = const Color(0xFF8B0000);

            final text = gen ? '✕' : number.toString();

            return GestureDetector(
              onTap: () {
                setState(() {
                  // max. 6 Favoriten
                  if (fav) {
                    _favorites[tipIndex].remove(number);
                  } else {
                    if (_favorites[tipIndex].length >= numbersPerTip) return;
                    _favorites[tipIndex].add(number);
                  }
                });
              },
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: bg,
                  border: Border.all(color: border, width: 1),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          gen ? FontWeight.bold : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // ------------------------------------------------------------------
  // FINALE ZAHLEN + FIXIEREN
  // ------------------------------------------------------------------
  Widget _buildFinalRow(int index) {
    final nums = _generated[index];
    final blink = _finalBlink[index];

    final balls = List.generate(numbersPerTip, (i) {
      final n = (i < nums.length) ? nums[i] : null;
      return _buildBall(n, blink);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: balls,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _fixed[index],
                onChanged: (v) {
                  setState(() => _fixed[index] = v ?? false);
                },
              ),
              const Text(
                "Fixieren",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBall(int? n, bool blink) {
    final borderColor =
        blink ? Colors.redAccent : kLottoRed;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: n == null
          ? const SizedBox.shrink()
          : Center(
              child: Text(
                "$n",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
            ),
    );
  }

  // ------------------------------------------------------------------
  // TASKBAR
  // ------------------------------------------------------------------
  Widget _buildTaskBar(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF59D),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _allRunning ? null : _generateAll,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _allRunning ? Colors.grey : Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(_allRunning ? "Läuft…" : "Alle generieren"),
          ),
          ElevatedButton(
            onPressed: _clearAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text("Alle löschen"),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _mute = !_mute;
                LGSounds.mute = _mute;
              });
            },
            icon: Icon(
              _mute ? Icons.volume_off : Icons.volume_up,
              color: Colors.black,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
