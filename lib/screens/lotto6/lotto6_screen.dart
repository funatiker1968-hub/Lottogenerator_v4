import 'package:flutter/material.dart';

class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int numbersPerRow = 7;

  /// Ausgewählte Zahlen pro Tippfeld (Set, damit keine Doppelten)
  late final List<Set<int>> _selectedPerTip;

  @override
  void initState() {
    super.initState();
    _selectedPerTip = List.generate(tipCount, (_) => <int>{});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6C0), // leicht gelb wie Schein
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            Expanded(child: _buildTipsGrid()),
            _buildQuickBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      height: 56,
      color: const Color(0xFFFFD000),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: const Text(
        'LOTTO 6aus49',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.red,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 12 TIPPFELDER (mit 7×7-Raster 1–49)
  // ---------------------------------------------------------------------------
  Widget _buildTipsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.of(context).orientation;
        final columns = orientation == Orientation.portrait ? 2 : 3;

        const spacing = 8.0;
        final width = constraints.maxWidth;
        final cardWidth = (width - (columns - 1) * spacing) / columns;

        return SingleChildScrollView(
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(tipCount, (i) {
              return SizedBox(
                width: cardWidth,
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: _buildTipCard(i),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // EIN TIPPFELD MIT 7×7-Raster
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int tipIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFC00000), width: 1.5),
      ),
      child: Column(
        children: [
          // Kopfzeile "Tipp X"
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

          const Divider(height: 1, color: Color(0xFFC00000)),

          // Raster 1–49
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: maxNumber,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: numbersPerRow,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final number = index + 1;
                  final selected =
                      _selectedPerTip[tipIndex].contains(number);

                  return GestureDetector(
                    onTap: () => _onNumberTap(tipIndex, number),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFC00000),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          selected ? 'X' : '$number',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.normal,
                            color: selected
                                ? Colors.blue.shade900 // BLAUES KREUZ
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAP AUF ZAHL – BLAUES KREUZ EIN/AUS
  // ---------------------------------------------------------------------------
  void _onNumberTap(int tipIndex, int number) {
    setState(() {
      final set = _selectedPerTip[tipIndex];
      if (set.contains(number)) {
        set.remove(number); // abwählen
      } else {
        set.add(number); // ankreuzen
      }
    });
  }

  // ---------------------------------------------------------------------------
  // QUICKTIP-LEISTE (noch Dummy, nur Optik)
  // ---------------------------------------------------------------------------
  Widget _buildQuickBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        border: Border(
          top: BorderSide(color: Colors.black54, width: 1),
          bottom: BorderSide(color: Colors.black54, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _qbtn("Teilnahme"),
          _qbtn("Quicktipp"),
          _qbtn("Löschen"),
        ],
      ),
    );
  }

  Widget _qbtn(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
