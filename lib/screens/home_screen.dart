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
        padding: const EdgeInsets.all(16.0),
        childAspectRatio: 1.0,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          // Kachel 1: Lotto 6aus49
          _buildTile(
            context,
            Icons.confirmation_number,
            'Lotto 6aus49',
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Lotto6aus49Screen(),
              ),
            ),
          ),

          // Kachel 2: Eurojackpot
          _buildTile(
            context,
            Icons.euro,
            'Eurojackpot',
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EurojackpotScreen(),
              ),
            ),
          ),

          // Kachel 3: Import & Update
          _buildTile(
            context,
            Icons.cloud_download,
            'Import & Update',
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DatabaseStatusScreen(),
              ),
            ),
          ),

          // Kachel 4: Statistik (DB-basiert, Lotto 6aus49)
          _buildTile(
            context,
            Icons.bar_chart,
            'Statistik',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const StatisticsScreen(spieltyp: '6aus49'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0, color: color),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
