import 'dart:math';
import 'package:flutter/material.dart';

import 'core_colors.dart';
import 'core_dimensions.dart';
import 'superzahl_area.dart';
import 'core_sounds.dart';

/// ===========================================================================
/// LOTTO 6aus49 — Hauptscreen
/// 12 Tippfelder, 7×7 Grid, Favoriten, Sounds, Highlight-Durchlauf.
/// ===========================================================================
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

  bool _allRunning = false;
  bool _mute = false;

  @override
  void initState() {
    super.initState();
    _favorites = List.generate(tipCount, (_) => <int>{});
    _generated = List.generate(tipCount, (_) => <int>[]);
    _highlight = List.generate(tipCount, (_) => null);
    _fixed = List.generate(tipCount, (_) => false);
    LGSounds.mute = false;
  }

  // ====================================================================
  // EINEN TIPP GENERIEREN
  // ====================================================================
  Future<void> _generateTip(int index) async {
    if (_fixed[index]) return;
    if (_allRunning) return;

    final favs = Set<int>.from(_favorites[index]);
    final result = Set<int>.from(favs);

    while (result.length < numbersPerTip) {
      result.add(1 + _rng.nextInt(maxNumber));
    }

    final sorted = result.toList()..sort();

    setState(() => _generated[index] = sorted);

    await _runHighlightForTip(index);
  }

  // ====================================================================
  // DURCHLAUF 1..49 MIT SOUND + TREFFER-HIGHLIGHTS
  // ====================================================================
  Future<void> _runHighlightForTip(int index) async {
    final nums = _generated[index];
    if (nums.isEmpty) return;

    for (int n = 1; n <= maxNumber; n++) {
      if (!mounted) return;

      setState(() => _highlight[index] = n);

      // Lotto-Klicksound
      LGSounds.playTick();

      if (nums.contains(n)) {
        await Future.delayed(const Duration(milliseconds: 120));
      } else {
        await Future.delayed(const Duration(milliseconds: 45));
      }
    }

    if (!mounted) return;
    setState(() => _highlight[index] = null);

    await _finalBlink(index);
  }

  // ====================================================================
  // FINALE BLINKSEQUENZ DER 6 ZAHLEN
  // ====================================================================
  Future<void> _finalBlink(int index) async {
    final nums = _generated[index];
    if (nums.isEmpty) return;

    for (int r = 0; r < 3; r++) {
      for (final n in nums) {
        if (!mounted) return;
        setState(() => _highlight[index] = n);
        await Future.delayed(const Duration(milliseconds: 80));
      }
      setState(() => _highlight[index] = null);
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  // ====================================================================
  // ALLE TIPPS GENERIEREN
  // ====================================================================
  Future<void> _generateAll() async {
    if (_allRunning) return;

    setState(() => _allRunning = true);
    for (int i = 0; i < tipCount; i++) {
      await _generateTip(i);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    setState(() => _allRunning = false);
  }

  // ====================================================================
  // ALLES LÖSCHEN
  // ====================================================================
  void _clearAll() {
    setState(() {
      for (int i = 0; i < tipCount; i++) {
        _generated[i] = [];
        _highlight[i] = null;
      }
    });
  }

  // ====================================================================
  // BUILD
  // ====================================================================
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
            // 12 % Superzahl
            SizedBox(
              height: superHeight,
              child: SuperzahlArea(height: superHeight),
            ),

            // 80 % Tippfelder
            SizedBox(
              height: tipsHeight,
              child: _buildTipsArea(context, tipsHeight),
            ),

            // 8 % Taskbar
            SizedBox(
              height: taskHeight,
              child: _buildTaskBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // TIPPBEREICH
  // ====================================================================

Widget _buildTipsArea(BuildContext context) {
  final orientation = MediaQuery.of(context).orientation;
  final width = MediaQuery.of(context).size.width;

  final columns = (orientation == Orientation.portrait) ? 2 : 3;

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tipCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85, // bessere Proportionen
        ),
        itemBuilder: (context, index) =>
            _buildTipCard(context, index, width / columns, 260),
        ),
       ),
     );
   }

  // ====================================================================
  // EINZELNE TIPP-KARTE
  // ====================================================================
  Widget _buildTipCard(
      BuildContext context, int index, double width, double height) {
   final double gridHeight = height * 0.72;
    final double finalHeight = height * 0.28;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LottoDim.tipCardRadius),
        border: Border.all(color: kLottoGrey, width: 1),
      ),
      child: Column(
        children: [
          // Titel
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tipp ${index + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),

          // Grid
          SizedBox(
            height: gridHeight,
            child: _buildNumberGrid(index),
          ),

          // Finale Reihe
          SizedBox(
            height: finalHeight,
            child: _buildFinalRow(index),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // GRID 1..49
  // ====================================================================
  Widget _buildNumberGrid(int tipIndex) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      itemCount: maxNumber,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: LottoDim.gridColumns,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        childAspectRatio: 0.9,
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
              if (fav) {
                _favorites[tipIndex].remove(number);
              } else {
                _favorites[tipIndex].add(number);
              }
            });
          },
          child: Container(
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
                  fontWeight: gen ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ====================================================================
  // FINALE ZAHLEN + FIXIEREN
  // ====================================================================
  Widget _buildFinalRow(int index) {
    final nums = _generated[index];

    final balls = List.generate(6, (i) {
      final n = (i < nums.length) ? nums[i] : null;
      return _buildBall(n);
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

  Widget _buildBall(int? n) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: kLottoRed, width: 1.4),
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

  // ====================================================================
  // TASKBAR
  // ====================================================================
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
