import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/historie_button.dart';
import '../widgets/statistik_button.dart';
import 'import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  Duration _timeUntilLotto = Duration.zero;
  Duration _timeUntilEuro = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdowns());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCountdowns() {
    final now = DateTime.now();
    _timeUntilLotto = _nextLottoDraw(now).difference(now);
    _timeUntilEuro = _nextEuroDraw(now).difference(now);

    if (_timeUntilLotto.isNegative) _timeUntilLotto = Duration.zero;
    if (_timeUntilEuro.isNegative) _timeUntilEuro = Duration.zero;

    setState(() {});
  }

  DateTime _nextLottoDraw(DateTime now) {
    const days = [DateTime.wednesday, DateTime.saturday];
    return _nextDraw(now, days, 19, 25);
  }

  DateTime _nextEuroDraw(DateTime now) {
    const days = [DateTime.tuesday, DateTime.friday];
    return _nextDraw(now, days, 20, 0);
  }

  DateTime _nextDraw(DateTime now, List<int> days, int hour, int minute) {
    DateTime d = DateTime(now.year, now.month, now.day, hour, minute);
    if (days.contains(now.weekday) && d.isAfter(now)) return d;

    for (int i = 1; i <= 7; i++) {
      d = d.add(const Duration(days: 1));
      if (days.contains(d.weekday)) {
        return DateTime(d.year, d.month, d.day, hour, minute);
      }
    }
    return d;
  }

  String _fmt(Duration d) {
    int sec = d.inSeconds;
    if (sec < 0) sec = 0;

    final days = sec ~/ 86400;
    final hours = (sec % 86400) ~/ 3600;
    final mins = (sec % 3600) ~/ 60;
    final secs = sec % 60;

    final dStr = days > 0 ? '${days}T ' : '';
    return '$dStr${hours.toString().padLeft(2, '0')}:'
        '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lottogenerator"),
        actions: const [
          StatistikButton(),
          HistorieButton(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Nächste Lottoziehung in:", style: Theme.of(context).textTheme.titleMedium),
            Text(_fmt(_timeUntilLotto), style: const TextStyle(fontSize: 28)),

            const SizedBox(height: 24),

            Text("Nächste Eurojackpot-Ziehung in:", style: Theme.of(context).textTheme.titleMedium),
            Text(_fmt(_timeUntilEuro), style: const TextStyle(fontSize: 28)),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Daten-Import"),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
