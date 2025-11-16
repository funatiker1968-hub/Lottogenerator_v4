import 'package:flutter/material.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lottogenerator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isPortrait
            // Hochformat: übereinander
            ? Column(
                children: const [
                  Expanded(
                    child: _GameCard(
                      title: "Lotto 6aus49",
                      subtitle: "Zufalls-Tipps im Scheinstil mit Superzahl",
                      nextDrawInfo: "Ziehungen: Mi & Sa",
                      color: Colors.yellow,
                      textColor: Colors.black,
                      targetScreen: Lotto6aus49Screen(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: _GameCard(
                      title: "Eurojackpot",
                      subtitle: "8 Tippfelder + Eurozahlen",
                      nextDrawInfo: "Ziehungen: Di & Fr",
                      color: Colors.blue,
                      textColor: Colors.white,
                      targetScreen: EurojackpotScreen(),
                    ),
                  ),
                ],
              )
            // Querformat: nebeneinander
            : Row(
                children: const [
                  Expanded(
                    child: _GameCard(
                      title: "Lotto 6aus49",
                      subtitle: "Zufalls-Tipps im Scheinstil mit Superzahl",
                      nextDrawInfo: "Ziehungen: Mi & Sa",
                      color: Colors.yellow,
                      textColor: Colors.black,
                      targetScreen: Lotto6aus49Screen(),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _GameCard(
                      title: "Eurojackpot",
                      subtitle: "8 Tippfelder + Eurozahlen",
                      nextDrawInfo: "Ziehungen: Di & Fr",
                      color: Colors.blue,
                      textColor: Colors.white,
                      targetScreen: EurojackpotScreen(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String nextDrawInfo;
  final Color color;
  final Color textColor;
  final Widget targetScreen;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.nextDrawInfo,
    required this.color,
    required this.textColor,
    required this.targetScreen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              spreadRadius: 3,
              offset: Offset(5, 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.9),
                ),
              ),
              const Spacer(),
              Text(
                nextDrawInfo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
