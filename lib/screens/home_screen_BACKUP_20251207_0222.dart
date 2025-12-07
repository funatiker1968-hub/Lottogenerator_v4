import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'lotto_6aus49_screen.dart';
import 'eurojackpot_screen.dart';
import '../widgets/historie_button.dart';
import '../widgets/statistik_button.dart';
import '../models/lotto_data.dart';
import '../services/lotto_database_erweitert.dart' as erweiterteDB;

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
  
  // Echte Daten
  List<LottoZiehung> _lottoZiehungen = [];
  List<LottoZiehung> _euroZiehungen = [];
  bool _datenLaden = false;

  @override
  void initState() {
    super.initState();
    _updateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdowns();
    });
    _ladeEchteDaten();
  }

  Future<void> _ladeEchteDaten() async {
    setState(() => _datenLaden = true);
    
    try {
      // Hole letzte 2 Ziehungen für Lotto 6aus49
      final lottoDaten = await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
        spieltyp: '6aus49',
        limit: 2,
      );
      
      // Hole letzte 2 Ziehungen für Eurojackpot
      final euroDaten = await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
        spieltyp: 'Eurojackpot',
        limit: 2,
      );
      
      setState(() {
        _lottoZiehungen = lottoDaten;
        _euroZiehungen = euroDaten;
        _datenLaden = false;
      });
      
      print('✅ Echte Daten geladen: ${_lottoZiehungen.length} Lotto, ${_euroZiehungen.length} Euro');
    } catch (error) {
      print('⚠️ Keine echten Daten verfügbar: $error');
      setState(() => _datenLaden = false);
    }
  }

  Future<void> _playSound() async {
    await _audioPlayer.play(AssetSource('sounds/click.mp3'));
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateCountdowns() {
    final now = DateTime.now();
    final lottoNext = _nextLottoDraw(now);
    final euroNext = _nextEuroDraw(now);

    setState(() {
      _timeUntilLotto = lottoNext.difference(now).isNegative
          ? Duration.zero
          : lottoNext.difference(now);
      _timeUntilEuro = euroNext.difference(now).isNegative
          ? Duration.zero
          : euroNext.difference(now);
    });
  }

  // Lotto 6aus49: Ziehungen Mi & Sa, 19:25
  DateTime _nextLottoDraw(DateTime now) {
    const drawWeekdays = [DateTime.wednesday, DateTime.saturday];
    const drawHour = 19;
    const drawMinute = 25;

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      drawHour,
      drawMinute,
    );

    bool isDrawDay(int weekday) => drawWeekdays.contains(weekday);

    if (!isDrawDay(now.weekday) || candidate.isBefore(now)) {
      // nächstes Ziehungsdatum suchen
      for (int i = 0; i < 7; i++) {
        candidate = candidate.add(const Duration(days: 1));
        if (isDrawDay(candidate.weekday)) {
          candidate = DateTime(
            candidate.year,
            candidate.month,
            candidate.day,
            drawHour,
            drawMinute,
          );
          break;
        }
      }
    }

    return candidate;
  }

  // Eurojackpot: Ziehungen Di & Fr, 20:00
  DateTime _nextEuroDraw(DateTime now) {
    const drawWeekdays = [DateTime.tuesday, DateTime.friday];
    const drawHour = 20;
    const drawMinute = 0;

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      drawHour,
      drawMinute,
    );

    bool isDrawDay(int weekday) => drawWeekdays.contains(weekday);

    if (!isDrawDay(now.weekday) || candidate.isBefore(now)) {
      for (int i = 0; i < 7; i++) {
        candidate = candidate.add(const Duration(days: 1));
        if (isDrawDay(candidate.weekday)) {
          candidate = DateTime(
            candidate.year,
            candidate.month,
            candidate.day,
            drawHour,
            drawMinute,
          );
          break;
        }
      }
    }

    return candidate;
  }

  String _formatDuration(Duration d) {
    int totalSeconds = d.inSeconds;
    if (totalSeconds < 0) totalSeconds = 0;

    final days = totalSeconds ~/ (24 * 3600);
    final hours = (totalSeconds % (24 * 3600)) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final dPart = days > 0 ? '${days}T ' : '';
    final hPart = hours.toString().padLeft(2, '0');
    final mPart = minutes.toString().padLeft(2, '0');
    final sPart = seconds.toString().padLeft(2, '0');

    return '$dPart$hPart:$mPart:$sPart';
  }

  // Formatierung für echte Ziehungen
  String _formatEchteZiehung(LottoZiehung ziehung) {
    final wochentag = _getGermanWeekday(ziehung.datum.weekday);
    final datum = ziehung.formatierterDatum;
    final zahlen = ziehung.zahlen.map((z) => z.toString().padLeft(2, '0')).join(' ');
    
    return '$wochentag $datum: $zahlen | SZ: ${ziehung.superzahl.toString().padLeft(2, '0')}';
  }

  String _getGermanWeekday(int weekday) {
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[weekday - 1];
  }

  // Fallback-Daten falls keine echten Daten verfügbar
  List<String> get _lottoFallbackDaten {
    if (_lottoZiehungen.isNotEmpty) {
      return _lottoZiehungen.map(_formatEchteZiehung).toList();
    }
    return [
      'Mi 12.11.2025: 5 11 18 24 37 42 | SZ: 7',
      'Sa 08.11.2025: 3 9 16 28 33 47 | SZ: 2',
    ];
  }

  List<String> get _euroFallbackDaten {
    if (_euroZiehungen.isNotEmpty) {
      // Eurojackpot hat 5 Hauptzahlen + 2 Eurozahlen
      return _euroZiehungen.map((ziehung) {
        final wochentag = _getGermanWeekday(ziehung.datum.weekday);
        final datum = ziehung.formatierterDatum;
        
        // Sicherstellen, dass wir genug Zahlen haben
        if (ziehung.zahlen.length >= 7) {
          final hauptzahlen = ziehung.zahlen.take(5).map((z) => z.toString().padLeft(2, '0')).join(' ');
          final eurozahlen = ziehung.zahlen.skip(5).take(2).map((z) => z.toString().padLeft(2, '0')).join(', ');
          return '$wochentag $datum: $hauptzahlen | Euro: $eurozahlen';
        } else {
          return '$wochentag $datum: ${ziehung.zahlen.map((z) => z.toString().padLeft(2, '0')).join(' ')}';
        }
      }).toList();
    }
    return [
      'Fr 14.11.2025: 4 17 25 38 45 | Euro: 3, 8',
      'Di 11.11.2025: 7 12 29 41 49 | Euro: 2, 10',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    // Schatten für plastische Kacheln
    final shadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.20),
        blurRadius: 18,
        spreadRadius: 2,
        offset: const Offset(4, 8),
      ),
    ];

    final lottoCountdownText =
        'Nächste Ziehung in ${_formatDuration(_timeUntilLotto)}';
    final euroCountdownText =
        'Nächste Ziehung in ${_formatDuration(_timeUntilEuro)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottogenerator'),
        actions: [
          if (_datenLaden)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          StatistikButton(audioPlayer: _audioPlayer),
          HistorieButton(audioPlayer: _audioPlayer),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isPortrait
            // Hochkant: Kacheln untereinander
            ? Column(
                children: [
                  Expanded(
                    child: _GameCard(
                      title: 'Lotto 6aus49',
                      subtitle: '12 Tippfelder im Scheinstil mit Superzahl',
                      drawDaysText: 'Ziehungen: Mittwoch & Samstag',
                      countdownText: lottoCountdownText,
                      lastDrawLines: _lottoFallbackDaten,
                      color: Colors.yellow.shade700,
                      textColor: Colors.black,
                      shadow: shadow,
                      onTap: () {
                        _playSound();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const Lotto6aus49Screen(),
                          ),
                        );
                      },
                      hatEchteDaten: _lottoZiehungen.isNotEmpty,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _GameCard(
                      title: 'Eurojackpot',
                      subtitle: '8 Tippfelder + 2 Eurozahlen',
                      drawDaysText: 'Ziehungen: Dienstag & Freitag',
                      countdownText: euroCountdownText,
                      lastDrawLines: _euroFallbackDaten,
                      color: Colors.blue.shade600,
                      textColor: Colors.white,
                      shadow: shadow,
                      onTap: () {
                        _playSound();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EurojackpotScreen(),
                          ),
                        );
                      },
                      hatEchteDaten: _euroZiehungen.isNotEmpty,
                    ),
                  ),
                ],
              )
            // Querformat: Kacheln nebeneinander
            : Row(
                children: [
                  Expanded(
                    child: _GameCard(
                      title: 'Lotto 6aus49',
                      subtitle: '12 Tippfelder im Scheinstil mit Superzahl',
                      drawDaysText: 'Ziehungen: Mittwoch & Samstag',
                      countdownText: lottoCountdownText,
                      lastDrawLines: _lottoFallbackDaten,
                      color: Colors.yellow.shade700,
                      textColor: Colors.black,
                      shadow: shadow,
                      onTap: () {
                        _playSound();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const Lotto6aus49Screen(),
                          ),
                        );
                      },
                      hatEchteDaten: _lottoZiehungen.isNotEmpty,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _GameCard(
                      title: 'Eurojackpot',
                      subtitle: '8 Tippfelder + 2 Eurozahlen',
                      drawDaysText: 'Ziehungen: Dienstag & Freitag',
                      countdownText: euroCountdownText,
                      lastDrawLines: _euroFallbackDaten,
                      color: Colors.blue.shade600,
                      textColor: Colors.white,
                      shadow: shadow,
                      onTap: () {
                        _playSound();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EurojackpotScreen(),
                          ),
                        );
                      },
                      hatEchteDaten: _euroZiehungen.isNotEmpty,
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: _lottoZiehungen.isEmpty && _euroZiehungen.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                _playSound();
                Navigator.pushNamed(context, '/historie');
              },
              icon: const Icon(Icons.add_chart),
              label: const Text('Daten hinzufügen'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}

// Reusable plastische Kachel
class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String drawDaysText;
  final String countdownText;
  final List<String> lastDrawLines;
  final Color color;
  final Color textColor;
  final List<BoxShadow> shadow;
  final VoidCallback onTap;
  final bool hatEchteDaten;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.drawDaysText,
    required this.countdownText,
    required this.lastDrawLines,
    required this.color,
    required this.textColor,
    required this.shadow,
    required this.onTap,
    this.hatEchteDaten = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel mit Echte-Daten-Indikator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (hatEchteDaten)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Untertitel
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),
              // Letzte Ziehungen
              Text(
                hatEchteDaten ? 'Aktuelle Ziehungen:' : 'Beispiel-Ziehungen:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              ...lastDrawLines.map(
                (line) => Text(
                  line,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.9),
                  ),
                ),
              ),
              const Spacer(),
              // Info + Countdown
              Text(
                drawDaysText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                countdownText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
