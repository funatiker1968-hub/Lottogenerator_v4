import 'package:flutter/material.dart';

import 'home_tile.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';

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
    if (isPortrait) {
      return Column(
        children: [
          Expanded(
            child: HomeTile(
              title: 'Lotto 6aus49',
              subtitle: '12 Tippfelder im Scheinstil mit Superzahl',
              drawDaysText: 'Ziehungen: Mittwoch & Samstag',
              countdownText: lottoCountdown,
              lastDrawLines: lottoLines,
              color: Colors.yellow.shade700,
              textColor: Colors.black,
              hatEchteDaten: lottoLines.length > 2,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Lotto6aus49Screen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: HomeTile(
              title: 'Eurojackpot',
              subtitle: '8 Tippfelder + 2 Eurozahlen',
              drawDaysText: 'Ziehungen: Dienstag & Freitag',
              countdownText: euroCountdown,
              lastDrawLines: euroLines,
              color: Colors.blue.shade600,
              textColor: Colors.white,
              hatEchteDaten: euroLines.length > 2,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EurojackpotScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Querformat
    return Row(
      children: [
        Expanded(
          child: HomeTile(
            title: 'Lotto 6aus49',
            subtitle: '12 Tippfelder im Scheinstil mit Superzahl',
            drawDaysText: 'Ziehungen: Mittwoch & Samstag',
            countdownText: lottoCountdown,
            lastDrawLines: lottoLines,
            color: Colors.yellow.shade700,
            textColor: Colors.black,
            hatEchteDaten: lottoLines.length > 2,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Lotto6aus49Screen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: HomeTile(
            title: 'Eurojackpot',
            subtitle: '8 Tippfelder + 2 Eurozahlen',
            drawDaysText: 'Ziehungen: Dienstag & Freitag',
            countdownText: euroCountdown,
            lastDrawLines: euroLines,
            color: Colors.blue.shade600,
            textColor: Colors.white,
            hatEchteDaten: euroLines.length > 2,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EurojackpotScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
