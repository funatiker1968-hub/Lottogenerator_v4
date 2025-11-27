// EOF2 – superzahl_area.dart (Layout, noch keine Animation)

import 'package:flutter/material.dart';

/// Superzahl-Bereich oben im Lotto-Schein-Stil.
/// 0–9 Leiste links, große Kugel rechts, Start-Button daneben.
/// Noch keine Animation – nur statisches Layout.

class SuperzahlArea extends StatelessWidget {
  final double height;

  const SuperzahlArea({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFFFF6C0),
      child: Row(
        children: [
          // Linke Lauflicht-Leiste: 0–9
          Expanded(
            child: _buildNumberStrip(),
          ),

          const SizedBox(width: 16),

          // Rechte große Kugel + Start
          _buildBallArea(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Balken 0–9
  // ---------------------------------------------------------------------------
  Widget _buildNumberStrip() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD000),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(10, (i) {
          return Container(
            width: 30,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6C0),
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "$i",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kugel + Start-Button
  // ---------------------------------------------------------------------------
  Widget _buildBallArea(BuildContext context) {
    return Row(
      children: [
        // Große Kugel
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellow.shade200,
            border: Border.all(color: Colors.red, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6)
            ],
          ),
          child: const Center(
            child: Text(
              "0",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Start Button
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Start",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
// EOF2

