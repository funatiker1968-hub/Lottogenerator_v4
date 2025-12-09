import 'package:flutter/material.dart';
import 'home_tile.dart';

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
    // Verwende die existierende HomeTile Klasse mit korrekten Parametern
    final lottoTile = HomeTile(
      title: 'Lotto 6aus49',
      icon: Icons.numbers,
      color: Colors.blue,
      route: '/lotto6',
    );

    final euroTile = HomeTile(
      title: 'EuroJackpot',
      icon: Icons.euro,
      color: Colors.green,
      route: '/eurojackpot',
    );

    // Erweiterte Tiles für zusätzliche Info
    final statistikTile = HomeTile(
      title: 'Statistik',
      icon: Icons.bar_chart,
      color: Colors.orange,
      route: '/statistik',
    );

    final historieTile = HomeTile(
      title: 'Historie',
      icon: Icons.history,
      color: Colors.purple,
      route: '/historie',
    );

    // Layout basierend auf Ausrichtung
    if (isPortrait) {
      return Column(
        children: [
          // Erste Zeile: Lotto und EuroJackpot
          Row(
            children: [
              Expanded(child: lottoTile),
              const SizedBox(width: 16),
              Expanded(child: euroTile),
            ],
          ),
          const SizedBox(height: 16),
          // Info Container für Countdowns
          _buildInfoContainer(context),
          const SizedBox(height: 16),
          // Zweite Zeile: Statistik und Historie
          Row(
            children: [
              Expanded(child: statistikTile),
              const SizedBox(width: 16),
              Expanded(child: historieTile),
            ],
          ),
        ],
      );
    } else {
      // Landscape Layout
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linke Spalte: Tiles
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: lottoTile),
                    const SizedBox(width: 16),
                    Expanded(child: euroTile),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: statistikTile),
                    const SizedBox(width: 16),
                    Expanded(child: historieTile),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Rechte Spalte: Info
          Expanded(
            flex: 1,
            child: _buildInfoContainer(context),
          ),
        ],
      );
    }
  }

  Widget _buildInfoContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nächste Ziehungen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCountdownRow('Lotto 6aus49', lottoCountdown),
          const SizedBox(height: 8),
          _buildCountdownRow('EuroJackpot', euroCountdown),
          const Divider(height: 24),
          const Text(
            'Letzte Ziehungen',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildLastDrawsInfo('Lotto:', lottoLines),
          const SizedBox(height: 8),
          ..._buildLastDrawsInfo('EuroJackpot:', euroLines),
        ],
      ),
    );
  }

  Widget _buildCountdownRow(String label, String countdown) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueGrey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            countdown,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLastDrawsInfo(String title, List<String> lines) {
    return [
      Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 2),
            child: Text(
              line,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
    ];
  }
}
