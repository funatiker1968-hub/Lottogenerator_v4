import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart' as erweiterteDB;

/// Statistik zu einer einzelnen Zahl
class ZahlStatistik {
  final int zahl;
  final int haeufigkeit;
  /// Tage seit letztem Auftreten (oder -1, wenn in der Stichprobe nie gezogen)
  final int ausbleibendTage;
  /// Durchschnittlicher Abstand in Tagen zwischen zwei Treffern (gerundet auf 1 Nachkommastelle)
  final double durchschnittlicherAbstandTage;

  const ZahlStatistik({
    required this.zahl,
    required this.haeufigkeit,
    required this.ausbleibendTage,
    required this.durchschnittlicherAbstandTage,
  });
}

/// Gesamt-Statistik für ein Spiel (z.B. 6aus49)
class LottoStatistikErgebnis {
  final String spieltyp;
  final int anzahlZiehungen;
  final DateTime? ersteZiehung;
  final DateTime? letzteZiehung;
  /// Liste aller Zahlen 1..maxZahl mit Statistik
  final List<ZahlStatistik> zahlen;

  const LottoStatistikErgebnis({
    required this.spieltyp,
    required this.anzahlZiehungen,
    required this.ersteZiehung,
    required this.letzteZiehung,
    required this.zahlen,
  });

  bool get hatDaten => anzahlZiehungen > 0;
}

class Zahlenpaar {
  final int erste;
  final int zweite;
  final int haeufigkeit;

  const Zahlenpaar({
    required this.erste,
    required this.zweite,
    required this.haeufigkeit,
  });
}

/// Zentrale Statistik-Funktionen für Lotto-Daten.
/// Greift nur lesend auf ErweiterteLottoDatenbank zu.
class StatistikService {
  const StatistikService._();

  /// A) Basis-Statistik:
  /// - Häufigkeiten
  /// - Ausbleiber (Tage seit letztem Auftreten)
  /// - Durchschnittlicher Abstand in Tagen
  static Future<LottoStatistikErgebnis> berechneBasisStatistik({
    required String spieltyp,
    required int maxZahl,
    int? limitZiehungen,
  }) async {
    // Wir holen "limitZiehungen" letzte Ziehungen – bei null ein recht großer Standardwert.
    final ziehungen = await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
      spieltyp: spieltyp,
      limit: limitZiehungen ?? 2000,
    );

    if (ziehungen.isEmpty) {
      return LottoStatistikErgebnis(
        spieltyp: spieltyp,
        anzahlZiehungen: 0,
        ersteZiehung: null,
        letzteZiehung: null,
        zahlen: List.generate(
          maxZahl,
          (i) => ZahlStatistik(
            zahl: i + 1,
            haeufigkeit: 0,
            ausbleibendTage: -1,
            durchschnittlicherAbstandTage: 0.0,
          ),
        ),
      );
    }

    // Aufsteigend sortieren nach Datum, damit Abstände stimmen.
    final sortierte = [...ziehungen]..sort((a, b) => a.datum.compareTo(b.datum));
    final erste = sortierte.first.datum;
    final letzte = sortierte.last.datum;

    final counts = <int, int>{};
    final lastDates = <int, DateTime>{};
    final abstaende = <int, List<int>>{};

    for (final z in sortierte) {
      for (final zahl in z.zahlen) {
        if (zahl <= 0 || zahl > maxZahl) {
          continue; // ignorieren, falls Eurozahlen o.ä. in derselben Liste landen
        }

        counts[zahl] = (counts[zahl] ?? 0) + 1;

        final prevDate = lastDates[zahl];
        if (prevDate != null) {
          final diffTage = z.datum.difference(prevDate).inDays;
          if (diffTage >= 0) {
            (abstaende[zahl] ??= <int>[]).add(diffTage);
          }
        }
        lastDates[zahl] = z.datum;
      }
    }

    final zahlenStat = <ZahlStatistik>[];
    for (var n = 1; n <= maxZahl; n++) {
      final h = counts[n] ?? 0;
      final last = lastDates[n];
      final ausbleibend = last == null ? -1 : letzte.difference(last).inDays;
      final gaps = abstaende[n] ?? const <int>[];

      double avg = 0.0;
      if (gaps.isNotEmpty) {
        final sum = gaps.fold<int>(0, (acc, v) => acc + v);
        avg = sum / gaps.length;
      }

      zahlenStat.add(
        ZahlStatistik(
          zahl: n,
          haeufigkeit: h,
          ausbleibendTage: ausbleibend,
          durchschnittlicherAbstandTage: double.parse(avg.toStringAsFixed(1)),
        ),
      );
    }

    // Standard-Sortierung: Häufigste Zahlen zuerst.
    zahlenStat.sort((a, b) => b.haeufigkeit.compareTo(a.haeufigkeit));

    return LottoStatistikErgebnis(
      spieltyp: spieltyp,
      anzahlZiehungen: sortierte.length,
      ersteZiehung: erste,
      letzteZiehung: letzte,
      zahlen: zahlenStat,
    );
  }

  /// E) Zahlenpaar-Analyse:
  /// Zählt alle Paare (erste, zweite), wie oft sie gemeinsam in Ziehungen vorkamen.
  /// Rückgabe ist nach Häufigkeit absteigend sortiert.
  static Future<List<Zahlenpaar>> berechneZahlenpaare({
    required String spieltyp,
    int? limitZiehungen,
    int? maxZahl,
  }) async {
    final ziehungen = await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
      spieltyp: spieltyp,
      limit: limitZiehungen ?? 2000,
    );

    if (ziehungen.isEmpty) return const <Zahlenpaar>[];

    final pairCounts = <String, int>{};

    for (final z in ziehungen) {
      final zahlen = z.zahlen
          .where((n) => n > 0 && (maxZahl == null || n <= maxZahl))
          .toList()
        ..sort();

      for (var i = 0; i < zahlen.length; i++) {
        for (var j = i + 1; j < zahlen.length; j++) {
          final a = zahlen[i];
          final b = zahlen[j];
          final key = '$a-$b';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    final ergebnis = <Zahlenpaar>[];
    pairCounts.forEach((key, value) {
      final parts = key.split('-');
      if (parts.length == 2) {
        final a = int.tryParse(parts[0]);
        final b = int.tryParse(parts[1]);
        if (a != null && b != null) {
          ergebnis.add(Zahlenpaar(erste: a, zweite: b, haeufigkeit: value));
        }
      }
    });

    ergebnis.sort((a, b) => b.haeufigkeit.compareTo(a.haeufigkeit));
    return ergebnis;
  }

  /// F) Datenpflege:
  /// Sucht Dubletten pro Datum (mehr als eine Ziehung mit gleichem Datum für einen Spieltyp).
  /// Gibt eine Map Datum -> Anzahl Einträge zurück, aber nur für Einträge mit count > 1.
  static Future<Map<DateTime, int>> findeDublettenProDatum({
    required String spieltyp,
    int? limitZiehungen,
  }) async {
    final ziehungen = await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
      spieltyp: spieltyp,
      limit: limitZiehungen ?? 100000,
    );
    final counts = <DateTime, int>{};

    for (final z in ziehungen) {
      final key = DateTime(z.datum.year, z.datum.month, z.datum.day);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final dubletten = <DateTime, int>{};
    counts.forEach((date, count) {
      if (count > 1) {
        dubletten[date] = count;
      }
    });

    return dubletten;
  }
}
