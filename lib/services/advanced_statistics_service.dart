import 'dart:math';
import 'package:lottogenerator_v4/services/lotto_database.dart';
import '../models/lotto_data.dart';

class AdvancedStatisticsService {
  final LottoDatabase _db = LottoDatabase();

  /// Lädt alle Ziehungen aus der DB und analysiert sie
  Future<Map<String, dynamic>> getFullAnalysis({String spieltyp = '6aus49'}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ziehungen',
      where: 'spieltyp = ?',
      whereArgs: [spieltyp],
      orderBy: 'datum DESC',
    );

    final ziehungen = maps.map((map) => LottoZiehung.fromMap(map)).toList();
    if (ziehungen.isEmpty) return {};

    final frequencies = _calculateFrequencies(ziehungen);
    final gaps = _calculateGaps(ziehungen);
    final recommendations = _generateRecommendations(frequencies, gaps);

    return {
      'spieltyp': spieltyp,
      'gesamtZiehungen': ziehungen.length,
      'letzteZiehung': ziehungen.first.datum,
      'frequencies': frequencies,
      'gaps': gaps,
      'recommendations': recommendations,
      'rawData': ziehungen,
    };
  }

  /// Zählt absolute Häufigkeiten aller Zahlen (1-49 oder 1-50+1-10)
  Map<int, int> _calculateFrequencies(List<LottoZiehung> ziehungen) {
    final Map<int, int> counts = {};
    for (var ziehung in ziehungen) {
      for (var number in ziehung.zahlen) {
        counts[number] = (counts[number] ?? 0) + 1;
      }
      // Superzahl nur bei Lotto 6aus49 zählen
      if (ziehung.spieltyp == '6aus49') {
        counts[ziehung.superzahl] = (counts[ziehung.superzahl] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Berechnet Lücken (Anzahl Ziehungen seit letztem Auftreten)
  Map<int, int> _calculateGaps(List<LottoZiehung> ziehungen) {
    final Map<int, int> lastSeen = {};
    final Map<int, int> gaps = {};
    final int total = ziehungen.length;

    // Von der neuesten zur ältesten Ziehung gehen
    for (int i = 0; i < ziehungen.length; i++) {
      final ziehung = ziehungen[i];
      for (var number in ziehung.zahlen) {
        if (!lastSeen.containsKey(number)) {
          gaps[number] = i; // Erste Sichtung = aktuelle Position
        }
        lastSeen[number] = i;
      }
      if (ziehung.spieltyp == '6aus49') {
        final sz = ziehung.superzahl;
        if (!lastSeen.containsKey(sz)) gaps[sz] = i;
        lastSeen[sz] = i;
      }
    }

    // Für Zahlen, die noch nie gezogen wurden, Lücke = total
    final maxNumber = ziehungen.first.spieltyp == 'eurojackpot' ? 50 : 49;
    for (int i = 1; i <= maxNumber; i++) {
      gaps.putIfAbsent(i, () => total);
    }
    if (ziehungen.first.spieltyp == '6aus49') {
      for (int i = 0; i <= 9; i++) {
        gaps.putIfAbsent(i, () => total);
      }
    }

    return gaps;
  }

  /// Generiert gewichtete Empfehlungen basierend auf Häufigkeit + Lücke
  List<Map<String, dynamic>> _generateRecommendations(
      Map<int, int> frequencies, Map<int, int> gaps) {
    final List<Map<String, dynamic>> scored = [];

    final maxGap = gaps.values.reduce(max);
    final maxFreq = frequencies.values.isNotEmpty
        ? frequencies.values.reduce(max).toDouble()
        : 1.0;

    gaps.forEach((number, gap) {
      final freq = frequencies[number] ?? 0;
      // Score: Hohe Häufigkeit gibt Punkte, große Lücke zieht Punkte ab
      final score = (freq / maxFreq * 70) - (gap / maxGap * 30) + 50;
      scored.add({
        'number': number,
        'frequency': freq,
        'gap': gap,
        'score': score.round(),
      });
    });

    scored.sort((a, b) => b['score'].compareTo(a['score']));
    return scored.take(15).toList(); // Top 15 Empfehlungen
  }

  /// Spezielle Analyse für Eurojackpot (5+2 Trennung)
  Future<Map<String, dynamic>> getEurojackpotAnalysis() async {
    final analysis = await getFullAnalysis(spieltyp: 'eurojackpot');
    if (analysis.isEmpty) return {};

    final ziehungen = analysis['rawData'] as List<LottoZiehung>;
    final mainNumbers = <int, int>{};
    final euroNumbers = <int, int>{};

    for (var ziehung in ziehungen) {
      for (int i = 0; i < ziehung.zahlen.length; i++) {
        final number = ziehung.zahlen[i];
        if (i < 5) {
          mainNumbers[number] = (mainNumbers[number] ?? 0) + 1;
        } else {
          euroNumbers[number] = (euroNumbers[number] ?? 0) + 1;
        }
      }
    }

    return {
      ...analysis,
      'mainNumbers': mainNumbers,
      'euroNumbers': euroNumbers,
    };
  }
}
