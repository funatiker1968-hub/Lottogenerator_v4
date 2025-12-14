import 'package:flutter/material.dart';
import 'import_screen.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto Generator'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3), // Korrekte Farbsyntax
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
              iconColor: Colors.white,
              tileColor: const Color(0xFF1565C0),
              textColor: Colors.white,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Lotto6aus49Screen()),
                );
              },
            ),
            
            _tile(
              context,
              title: 'Eurojackpot',
              icon: Icons.euro,
              iconColor: Colors.white,
              tileColor: const Color(0xFFF57C00),
              textColor: Colors.white,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EurojackpotScreen()),
                );
              },
            ),
            
            _tile(
              context,
              title: 'Statistik',
              icon: Icons.bar_chart,
              iconColor: Colors.black87,
              tileColor: const Color(0xFFC8E6C9),
              textColor: Colors.black87,
              onTap: () {
                _showComingSoon(context, 'Statistik');
              },
            ),
            
            _tile(
              context,
              title: 'Datenimport',
              icon: Icons.download,
              iconColor: Colors.white,
              tileColor: const Color(0xFF7B1FA2),
              textColor: Colors.white,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImportScreen()),
                );
              },
            ),
            
            _tile(
              context,
              title: 'Info',
              icon: Icons.info,
              iconColor: Colors.black87,
              tileColor: const Color(0xFFFFF176),
              textColor: Colors.black87,
              onTap: () {
                _showAppInfo(context);
              },
            ),
            
            _tile(
              context,
              title: 'Einstellungen',
              icon: Icons.settings,
              iconColor: Colors.black87,
              tileColor: const Color(0xFFE0E0E0),
              textColor: Colors.black87,
              onTap: () {
                _showComingSoon(context, 'Einstellungen');
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
    required Color iconColor,
    required Color tileColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('In Entwicklung'),
        content: Text('"$feature" wird in einem zukünftigen Update verfügbar sein.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Lottogenerator V4',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.casino, color: Colors.blue),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Offline-Lotto-Analyse für:\n'
          '• Lotto 6aus49\n'
          '• Eurojackpot\n\n'
          'Features:\n'
          '• Historische Daten\n'
          '• Statistische Analyse\n'
          '• Lokale SQLite-Datenbank\n'
          '• Keine Internetverbindung benötigt',
          textAlign: TextAlign.left,
        ),
      ],
    );
  }
}
