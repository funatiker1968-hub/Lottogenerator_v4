import 'package:flutter/material.dart';

class HomeTilesBlock extends StatelessWidget {
  final bool isPortrait;
  final String lottoCountdown;
  final String euroCountdown;
  final List<String> lottoLines;
  final List<String> euroLines;

  const HomeTilesBlock({
    super.key,
    required this.isPortrait,
    required this.lottoCountdown,
    required this.euroCountdown,
    required this.lottoLines,
    required this.euroLines,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isPortrait ? 1 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildTile(
          title: "Lotto 6aus49",
          color: Colors.amber.shade700,
          exampleLines: lottoLines,
          countdownLabel: "Ziehungen: Mittwoch & Samstag",
          countdown: lottoCountdown,
          onTap: () => Navigator.pushNamed(context, "/lotto"),
        ),
        _buildTile(
          title: "Eurojackpot",
          color: Colors.blue.shade600,
          exampleLines: euroLines,
          countdownLabel: "Ziehungen: Dienstag & Freitag",
          countdown: euroCountdown,
          onTap: () => Navigator.pushNamed(context, "/eurojackpot"),
        ),
      ],
    );
  }

  Widget _buildTile({
    required String title,
    required Color color,
    required List<String> exampleLines,
    required String countdownLabel,
    required String countdown,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            const Text(
              "Beispiel-Ziehungen:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...exampleLines
                .map((e) => Text(
                      e,
                      style: const TextStyle(fontSize: 13),
                    ))
                .toList(),
            const Spacer(),
            Text(
              countdownLabel,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              countdown,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
