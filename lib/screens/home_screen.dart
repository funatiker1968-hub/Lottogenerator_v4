import 'package:flutter/material.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lottogenerator v4')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _tile(
            context,
            title: 'Lotto 6aus49',
            icon: Icons.confirmation_number,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Lotto6aus49Screen()),
            ),
          ),
          _tile(
            context,
            title: 'Eurojackpot',
            icon: Icons.euro,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EurojackpotScreen()),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
