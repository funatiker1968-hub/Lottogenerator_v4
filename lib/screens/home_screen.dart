import 'package:flutter/material.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';
import 'statistics_screen.dart';
import 'database_status_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottogenerator v4'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _tile(
            context,
            Icons.confirmation_number,
            'Lotto 6aus49',
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Lotto6aus49Screen(),
              ),
            ),
          ),
          _tile(
            context,
            Icons.euro,
            'Eurojackpot',
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EurojackpotScreen(),
              ),
            ),
          ),
          _tile(
            context,
            Icons.cloud_download,
            'Import & Update',
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DatabaseStatusScreen(),
              ),
            ),
          ),
          _tile(
            context,
            Icons.bar_chart,
            'Statistik',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StatisticsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
