import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';

import '../widgets/historie_button.dart';
import '../widgets/statistik_button.dart';

import '../models/lotto_data.dart';
import '../services/lotto_database_erweitert.dart' as erweiterteDB;

import 'home_tiles_block.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  Duration _timeUntilLotto = Duration.zero;
  Duration _timeUntilEuro = Duration.zero;

  final AudioPlayer _audioPlayer = AudioPlayer();

  List<LottoZiehung> _lottoZiehungen = [];
  List<LottoZiehung> _euroZiehungen = [];
  bool _datenLaden = false;

  @override
  void initState() {
    super.initState();
    _updateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdowns());
    _ladeEchteDaten();
  }

  Future<void> _ladeEchteDaten() async {
    setState(() => _datenLaden = true);

    try {
      final lottoDaten =
          await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
        spieltyp: '6aus49',
        limit: 2,
      );

      final euroDaten =
          await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
        spieltyp: 'Eurojackpot',
        limit: 2,
      );

      setState(() {
        _lottoZiehungen = lottoDaten;
        _euroZiehungen = euroDaten;
        _datenLaden = false;
      });
    } catch (e) {
      setState(() => _datenLaden = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
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
    bool ok = days.contains(now.weekday) && d.isAfter(now);
    if (ok) return d;

    for (int i = 1; i <= 7; i++) {
      d = d.add(const Duration(days: 1));
      if (days.contains(d.weekday)) {
        return DateTime(d.year, d.month, d.day, hour, minute);
      }
    }

    return d;
  }

  String _format(Duration d) {
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

  List<String> get _lottoLines {
    if (_lottoZiehungen.isEmpty) {
      return [
        'Mi 12.11.2025: 5 11 18 24 37 42 | SZ: 7',
        'Sa 08.11.2025: 3 9 16 28 33 47 | SZ: 2',
      ];
    }
    return _lottoZiehungen.map(_fmtZiehung).toList();
  }

  List<String> get _euroLines {
    if (_euroZiehungen.isEmpty) {
      return [
        'Fr 14.11.2025: 4 17 25 38 45 | Euro: 3, 8',
        'Di 11.11.2025: 7 12 29 41 49 | Euro: 2, 10',
      ];
    }
    return _euroZiehungen.map(_fmtEuroZiehung).toList();
  }

  String _fmtZiehung(LottoZiehung z) {
    final w = ['Mo','Di','Mi','Do','Fr','Sa','So'][z.datum.weekday - 1];
    final d = z.formatierterDatum;
    final nums = z.zahlen.take(6).map((e)=>e.toString().padLeft(2,'0')).join(' ');
    return '$w $d: $nums | SZ: ${z.superzahl}';
  }

  String _fmtEuroZiehung(LottoZiehung z) {
    final w = ['Mo','Di','Mi','Do','Fr','Sa','So'][z.datum.weekday - 1];
    final d = z.formatierterDatum;

    if (z.zahlen.length >= 7) {
      final h = z.zahlen.take(5).map((e)=>e.toString().padLeft(2,'0')).join(' ');
      final e = z.zahlen.skip(5).take(2).map((e)=>e.toString().padLeft(2,'0')).join(', ');
      return '$w $d: $h | Euro: $e';
    }

    final joined = z.zahlen.map((e)=>e.toString().padLeft(2,'0')).join(' ');
    return '$w $d: $joined';
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottogenerator'),
        actions: [
          if (_datenLaden)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          StatistikButton(audioPlayer: _audioPlayer),
          HistorieButton(audioPlayer: _audioPlayer),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: HomeTilesBlock(
          isPortrait: isPortrait,
          lottoCountdown: _format(_timeUntilLotto),
          euroCountdown: _format(_timeUntilEuro),
          lottoLines: _lottoLines,
          euroLines: _euroLines,
        ),
      ),
    );
  }
}
// --- Nach dem bestehenden UI-Code z.B. in einer Button- oder Menü-Liste hinzufügen: ---
ElevatedButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ImportScreen()),
    );
  },
  child: const Text('Lotto-Import'),
),
