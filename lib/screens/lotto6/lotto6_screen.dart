// EOF1 - lotto6_screen.dart (Grundlayout im Lottoschein-Stil)
import 'dart:math';
import 'package:flutter/material.dart';

/// Einfache Lotto-6aus49 Oberfläche im Stil eines Lottoscheins.
/// Fokus: Layout (12 Tippfelder mit 1–49), Losnummer unten.
/// Noch keine Superzahl-Animation, keine Sounds.
class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;

  final Random _rng = Random();

  /// Ausgewählte Kästchen pro Tipp (nur für Darstellung der "X")
  late final List<Set<int>> _selectedPerTip;

  /// 7-stellige Losnummer unten links
  late String _losnummer;

  @override
  void initState() {
    super.initState();
    _selectedPerTip = List.generate(tipCount, (_) => <int>{});
    _generateNewLosnummer();
  }

  void _generateNewLosnummer() {
    _losnummer = List.generate(7, (_) => _rng.nextInt(10))
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final orientation = media.orientation;

    // Lottoschein-Hintergrund (hellgelb)
    const background = Color(0xFFFFF6C0);

    // 2 Spalten im Hochformat, 3 im Querformat (für Lesbarkeit)
    final int columns = orientation == Orientation.portrait ? 2 : 3;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            // TIPPFELDER – scrollbarer Bereich
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final totalWidth = constraints.maxWidth;
                    const spacing = 8.0;
                    final cardWidth =
                        (totalWidth - (columns - 1) * spacing) / columns;
                    final cardHeight = cardWidth * 1.6;

                    return SingleChildScrollView(
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
                    );
                  },
                ),
              ),
            ),
            _buildBottomLosnummerBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kopfbereich (Titel-Leiste)
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      height: 56,
      color: const Color(0xFFFFD000),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'LOTTO 6aus49',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Normalschein',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Einzelnes Tippfeld
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int tipIndex) {
    const borderColor = Color(0xFFC00000);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Titelzeile "Tipp X"
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.centerLeft,
            child: Text(
              'Tipp ${tipIndex + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),

          // Grid 1–49 im Stil des Lottoscheins
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: _buildNumberGrid(tipIndex),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grid: 1..49 (7×7) – Lottoschein-Stil
  // ---------------------------------------------------------------------------
  Widget _buildNumberGrid(int tipIndex) {
    const gridBorderColor = Color(0xFFC00000);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: maxNumber,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, i) {
        final number = i + 1;
        final selected = _selectedPerTip[tipIndex].contains(number);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedPerTip[tipIndex].remove(number);
              } else {
                _selectedPerTip[tipIndex].add(number);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: gridBorderColor, width: 0.8),
            ),
            child: Center(
              child: Text(
                selected ? 'X' : '$number',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.blue.shade900 : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Untere Losnummer-Leiste (7-stellige Zahl links)
  // ---------------------------------------------------------------------------
  Widget _buildBottomLosnummerBar() {
    const redBar = Color(0xFFD00000);

    return Container(
      height: 72,
      color: redBar,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Losnummer-Box
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Losnummer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (int i = 0; i < _losnummer.length; i++)
                        Container(
                          width: 18,
                          height: 24,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _losnummer[i],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(_generateNewLosnummer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                        child: const Text(
                          'Zufällig',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Platzhalter für Zusatzlotterien / Ziehungstage usw.
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildMiniBox('Zusatzspiele'),
                const SizedBox(width: 4),
                _buildMiniBox('Ziehungstage'),
                const SizedBox(width: 4),
                _buildMiniBox('Laufzeit'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBox(String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Spacer(),
            const Text(
              '…',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
// EOF1
