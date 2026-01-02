import 'package:flutter/material.dart';

import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';
import 'import_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottogenerator V4'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _tile(
              context,
              title: 'Lotto 6aus49',
              icon: Icons.confirmation_number,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Lotto6aus49Screen(),
                  ),
                );
              },
            ),
            _tile(
              context,
              title: 'Eurojackpot',
              icon: Icons.euro,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EurojackpotScreen(),
                  ),
                );
              },
            ),
            _tile(
              context,
              title: 'Datenimport',
              icon: Icons.download,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ImportScreen(),
                  ),
                );
              },
            ),
            _tile(
              context,
              title: 'Statistik',
              icon: Icons.bar_chart,
              onTap: () {
                // bewusst leer – kommt NACH Import & DB
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade800,
              Colors.grey.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
