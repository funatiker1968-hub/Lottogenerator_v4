import 'package:flutter/material.dart';

class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6C0), // Papiergelb
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
  // GESAMTER LOTTO-SCHEIN (2 Reihen × 6 Spalten)
  // ---------------------------------------------------------------------------
  Widget _buildFullSchein() {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9, // wie echter Schein, Querformat
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
                  children: List.generate(6, (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildTipCard(i + 1),
                    ),
                  )),
                ),
              ),
              Expanded(
                child: Row(
                  children: List.generate(6, (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildTipCard(i + 7),
                    ),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EINZEL-TIPP-KARTE (nur Titel, noch kein Raster)
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int number) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red.shade700, width: 1.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.red.shade700, width: 1.4),
              ),
            ),
            child: Text(
              "Tipp $number",
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                "Raster folgt",
                style: TextStyle(color: Colors.black54, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUICKTIP-LEISTE (unverändert)
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
