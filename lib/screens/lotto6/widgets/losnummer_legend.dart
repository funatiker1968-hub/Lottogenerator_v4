import 'package:flutter/material.dart';

/// Einheitliche Beschriftungs-/Klammerdarstellung wie auf dem Original-Lottoschein.
/// Wird sowohl unter der kleinen Losnummer als auch im Walzen-Dialog genutzt.
class LosnummerLegend extends StatelessWidget {
  final double fontSize;
  final double bracketHeight;

  const LosnummerLegend({
    super.key,
    this.fontSize = 10,
    this.bracketHeight = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Klammern unter allen 7 Feldern (Glücksspirale / Spiel 77)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 7 * 20,
              height: bracketHeight,
              child: CustomPaint(
                painter: _BracketPainter(color: Colors.black, width: 1.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "Glücksspirale   •   Spiel 77",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 6),

        // Klammern für SUPER 6 (letzte 6 Stellen)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 6 * 20,
              height: bracketHeight,
              child: CustomPaint(
                painter: _BracketPainter(color: Colors.black, width: 1.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "SUPER 6",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 6),

        // Klammer für Superzahl (letzte Stelle)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: bracketHeight,
              child: CustomPaint(
                painter: _BracketPainter(color: Colors.red, width: 1.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "Superzahl",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double width;

  _BracketPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final y = size.height * 0.7;

    // links kurz runter
    canvas.drawLine(const Offset(0, 0), Offset(0, y), paint);

    // waagerecht rüber
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // rechts kurz hoch
    canvas.drawLine(Offset(size.width, y), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
