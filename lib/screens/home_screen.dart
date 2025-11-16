import 'package:flutter/material.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildGameCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottogenerator v4'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wähle dein Spiel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diese App generiert zufällige Tipps für Lotto 6aus49 und Eurojackpot.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildGameCard(
                    context: context,
                    icon: Icons.casino,
                    title: 'Lotto 6aus49',
                    subtitle: '12 Spielfelder, Lauflicht-Animation, Superzahl',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Lotto6aus49Screen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildGameCard(
                    context: context,
                    icon: Icons.euro,
                    title: 'Eurojackpot',
                    subtitle: 'In Vorbereitung – Platzhalter-Ansicht',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EurojackpotScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Stand: 16.11.2025 15:47',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
