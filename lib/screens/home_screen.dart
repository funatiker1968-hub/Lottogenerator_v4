import 'dart:async';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  Duration lottoCountdown = Duration.zero;
  Duration euroCountdown = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateCountdowns();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // ---------- Ziehungszeiten ----------
  DateTime _nextLottoDraw() {
    DateTime now = DateTime.now();

    // Lotto: Mi 18:25 / Sa 19:25
    DateTime wednesday = DateTime(now.year, now.month, now.day, 18, 25);
    while (wednesday.weekday != DateTime.wednesday) {
      wednesday = wednesday.add(const Duration(days: 1));
    }

    DateTime saturday = DateTime(now.year, now.month, now.day, 19, 25);
    while (saturday.weekday != DateTime.saturday) {
      saturday = saturday.add(const Duration(days: 1));
    }

    if (now.isBefore(wednesday)) return wednesday;
    if (now.isBefore(saturday)) return saturday;

    return wednesday.add(const Duration(days: 7));
  }

  DateTime _nextEuroDraw() {
    DateTime now = DateTime.now();

    // Eurojackpot: Di + Fr jeweils 20:00
    DateTime tuesday = DateTime(now.year, now.month, now.day, 20, 0);
    while (tuesday.weekday != DateTime.tuesday) {
      tuesday = tuesday.add(const Duration(days: 1));
    }

    DateTime friday = DateTime(now.year, now.month, now.day, 20, 0);
    while (friday.weekday != DateTime.friday) {
      friday = friday.add(const Duration(days: 1));
    }

    if (now.isBefore(tuesday)) return tuesday;
    if (now.isBefore(friday)) return friday;

    return tuesday.add(const Duration(days: 7));
  }

  void _calculateCountdowns() {
    final now = DateTime.now();
    setState(() {
      lottoCountdown = _nextLottoDraw().difference(now);
      euroCountdown = _nextEuroDraw().difference(now);
    });
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${d.inDays}d ${two(d.inHours % 24)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}";
  }

  // ---------- Dummy-Ziehungen ----------
  final List<Map<String, dynamic>> lottoLastDraws = [
    {"date": "13.11.2025 (Do)", "numbers": "4 11 17 22 35 45", "super": "9"},
    {"date": "10.11.2025 (Mo)", "numbers": "1 9 22 34 41 48", "super": "3"},
  ];

  final List<Map<String, dynamic>> euroLastDraws = [
    {"date": "14.11.2025 (Fr)", "numbers": "7 14 21 26 38", "euro": "4 + 10"},
    {"date": "11.11.2025 (Di)", "numbers": "3 12 28 39 48", "euro": "3 + 9"},
  ];

  // ---------- UI-Kacheln ----------
  Widget _buildTile({
    required String title,
    required IconData icon,
    required Duration countdown,
    required List<Map<String, dynamic>> draws,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.blue.shade50,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 48, color: Colors.blue.shade700),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Nächste Ziehung in:",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              _formatDuration(countdown),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ...draws.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "${d['date']}\n${d['numbers']}"
                  "${d.containsKey('super') ? '  Superzahl: ${d['super']}' : ''}"
                  "${d.containsKey('euro') ? '  | Eurozahlen: ${d['euro']}' : ''}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lotto Generator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildTile(
              title: "Lotto 6aus49",
              icon: Icons.casino,
              countdown: lottoCountdown,
              draws: lottoLastDraws,
              onTap: () => Navigator.pushNamed(context, "/lotto649"),
            ),
            const SizedBox(height: 24),
            _buildTile(
              title: "Eurojackpot",
              icon: Icons.monetization_on,
              countdown: euroCountdown,
              draws: euroLastDraws,
              onTap: () => Navigator.pushNamed(context, "/eurojackpot"),
            ),
          ],
        ),
      ),
    );
  }
}
