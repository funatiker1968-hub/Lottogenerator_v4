// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'lotto6/lotto6_screen.dart';
import 'eurojackpot_screen.dart';
import 'database_import_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto Generator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _tile(
              context,
              title: 'Lotto 6aus49',
              icon: Icons.confirmation_number,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Lotto6Screen(),
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
                    builder: (_) => const DatabaseImportScreen(),
                  ),
                );
              },
            ),
            _tile(
              context,
              title: 'Statistik',
              icon: Icons.analytics,
              onTap: () {
                // kommt im nächsten Schritt
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
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
