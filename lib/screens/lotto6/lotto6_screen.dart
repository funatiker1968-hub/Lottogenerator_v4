import 'package:flutter/material.dart';
import 'dart:math';

class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int maxMarksPerTip = 6;

  /// Merkt ausgewählte Zahlen je Tippfeld
  late final List<Set<int>> _selectedPerTip;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _selectedPerTip = List.generate(tipCount, (_) => <int>{});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6C0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 6),
            Expanded(child: _buildFullSchein()),
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
      width: double.infinity,
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
  // GESAMTER LOTTO-SCHEIN – 2 Reihen × 6 Spalten
  // ---------------------------------------------------------------------------
  Widget _buildFullSchein() {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCE8),
            border: Border.all(color: Colors.red.shade700, width: 1.6),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildTipCard(i + 1),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildTipCard(i + 7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EIN TIPP MIT RASTER
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int tipNumber) {
    final int tipIndex = tipNumber - 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red.shade700, width: 1.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Titel
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.red.shade700, width: 1.4),
              ),
            ),
            child: Text(
              "Tipp $tipNumber",
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Raster 1–49 (7×7)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 1,
                  crossSpacing: 1,
                  childAspectRatio: 1.0,
                ),
                itemCount: maxNumber,
                itemBuilder: (context, i) {
                  final number = i + 1;
                  final isSelected = _selectedPerTip[tipIndex].contains(number);
                  return _buildNumberCell(tipIndex, number, isSelected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ZAHLENFELD + HAND-KREUZ
  // ---------------------------------------------------------------------------
  Widget _buildNumberCell(int tipIndex, int number, bool isSelected) {
    return GestureDetector(
      onTap: () => _onNumberTap(tipIndex, number, isSelected),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC00000), width: 0.8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                "$number",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.black.withOpacity(0.8) : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              CustomPaint(
                painter: _CrossPainter(),
                size: Size.infinite,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAP-LOGIK
  // ---------------------------------------------------------------------------
  void _onNumberTap(int tipIndex, int number, bool alreadySelected) {
    setState(() {
      final set = _selectedPerTip[tipIndex];

      if (alreadySelected) {
        set.remove(number);
        return;
      }

      if (set.length >= maxMarksPerTip) return;

      set.add(number);
    });
  }

  // ---------------------------------------------------------------------------
  // QUICKTIPP-FUNKTION (Block 2)
  // ---------------------------------------------------------------------------
  void _generateRandomTip(int tipIndex) {
    final set = <int>{};

    while (set.length < maxMarksPerTip) {
      set.add(_rng.nextInt(maxNumber) + 1);
    }

    _selectedPerTip[tipIndex]
      ..clear()
      ..addAll(set);
  }

  void _clearTip(int tipIndex) {
    _selectedPerTip[tipIndex].clear();
  }

  // ---------------------------------------------------------------------------
  // QUICKTIP-LEISTE
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
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (int i = 0; i < tipCount; i++) {
                  _generateRandomTip(i);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text("Quicktipp", style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (int i = 0; i < tipCount; i++) {
                  _clearTip(i);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text("Löschen", style: TextStyle(fontSize: 12)),
          ),
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

// -----------------------------------------------------------------------------
// CUSTOM PAINTER – Blaues Handkreuz
// -----------------------------------------------------------------------------
class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade900
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double pad = size.shortestSide * 0.15;

    canvas.drawLine(
        Offset(pad, pad), Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, pad), Offset(pad, size.height - pad), paint);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) => false;
}
