import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _dbInitFuture;

  @override
  void initState() {
    super.initState();
    _dbInitFuture = _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    print('🏁 HomeScreen wird geladen, starte Datenbank...');
    final db = LottoDatabase();
    await db.database;
    await db.close();
    print('✅ Datenbank-Initialisierung im HomeScreen abgeschlossen.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dbInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lottogenerator V4'),
          ),
          body: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            padding: const EdgeInsets.all(16),
            children: [
              // Kachel 1: Lotto 6aus49
              _buildTile(
                title: 'Lotto 6aus49',
                icon: Icons.confirmation_number,
                color: Colors.blue[100],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Lotto6aus49Screen(),
                    ),
                  );
                },
              ),
              // Kachel 2: Eurojackpot
              _buildTile(
                title: 'Eurojackpot',
                icon: Icons.euro,
                color: Colors.green[100],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EurojackpotScreen(),
                    ),
                  );
                },
              ),
              // Kachel 3: Import & Update
              _buildTile(
                title: 'Import & Update',
                icon: Icons.cloud_download,
                color: Colors.orange[100],
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Manueller Import wird später implementiert.'),
                    ),
                  );
                },
              ),
              // Kachel 4: Statistik
              _buildTile(
                title: 'Statistik',
                icon: Icons.bar_chart,
                color: Colors.purple[100],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(spieltyp: '6aus49'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile({
    required String title,
    required IconData icon,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
