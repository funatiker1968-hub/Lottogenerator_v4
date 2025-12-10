import 'dart:math';

import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

/// Ergebnis für die Was-wäre-wenn-Analyse eines einzelnen Tipps.
class WasWaereWennErgebnis {
  /// Anzahl analysierter Ziehungen
  final int anzahlZiehungen;

  /// Treffer pro Gewinnklasse (1..8)
  final Map<int, int> trefferProKlasse;

  /// Summe aller Ziehungen mit mindestens 3 Richtigen (inkl. SZ)
  final int gesamtTrefferAbDrei;

  /// Datum der ersten Ziehung mit Treffer (>=3 Richtige)
  final DateTime? ersteTrefferZiehung;

  /// Datum der letzten Ziehung mit Treffer (>=3 Richtige)
  final DateTime? letzteTrefferZiehung;

  WasWaereWennErgebnis({
    required this.anzahlZiehungen,
    required this.trefferProKlasse,
    required this.gesamtTrefferAbDrei,
    required this.ersteTrefferZiehung,
    required this.letzteTrefferZiehung,
  });
}

/// Ergebnis für die Zufalls-Simulation (C)
class ZufallsSimulationErgebnis {
  /// Anzahl zufälliger Tipps
  final int anzahlTipps;

  /// Durchschnittliche Treffer pro Gewinnklasse (über alle Zufallstipps)
  final Map<int, double> durchschnittTrefferProKlasse;

  ZufallsSimulationErgebnis({
    required this.anzahlTipps,
    required this.durchschnittTrefferProKlasse,
  });
}

/// Service für Was-wäre-wenn-Analysen:
/// A) Einzel-Tipp
/// B) Mehrere Tipps (z.B. 12 Tippfelder)
/// C) Zufallssimulation
class WasWaereWennService {
  /// A) Analysiere einen einzelnen Tipp über alle gespeicherten Ziehungen.
  ///
  /// [tipp.spieltyp] muss zum DB-Inhalt passen, z.B. '6aus49'.
  /// Optional: [onProgress] erhält (aktuelleZiehung, gesamtZiehungen).
  Future<WasWaereWennErgebnis> analysiereEinzelTipp(
    LottoZiehung tipp, {
    void Function(int current, int total)? onProgress,
  }) async {
    final ziehungen = await ErweiterteLottoDatenbank.holeAlleZiehungen(
      spieltyp: tipp.spieltyp,
    );

    return _analysiereTippMitZiehungen(
      tipp,
      ziehungen,
      onProgress: onProgress,
    );
  }

  /// B) Analysiere mehrere Tipps (z.B. alle 12 Tippfelder) gegen dieselben Ziehungen.
  ///
  /// Alle Tipps sollten denselben [spieltyp] verwenden.
  /// Rückgabe: Map von Tipp -> Ergebnis.
  Future<Map<LottoZiehung, WasWaereWennErgebnis>> analysiereMehrereTipps(
    List<LottoZiehung> tipps, {
    required String spieltyp,
    void Function(LottoZiehung tipp, int current, int total)? onProgress,
  }) async {
    final ziehungen = await ErweiterteLottoDatenbank.holeAlleZiehungen(
      spieltyp: spieltyp,
    );

    final ergebnisse = <LottoZiehung, WasWaereWennErgebnis>{};
    final total = tipps.length;

    for (var i = 0; i < tipps.length; i++) {
      final tipp = tipps[i];
      final erg = _analysiereTippMitZiehungen(
        tipp,
        ziehungen,
      );
      ergebnisse[tipp] = erg;
      if (onProgress != null) {
        onProgress(tipp, i + 1, total);
      }
    }

    return ergebnisse;
  }

  /// C) Simulation: viele zufällige Tipps generieren und statistisch auswerten.
  ///
  /// [anzahlTipps] z.B. 1000 oder 10000. [spieltyp] aktuell '6aus49'.
  /// Optional: [onProgress] erhält (aktuellerTippIndex, gesamtTipps).
  Future<ZufallsSimulationErgebnis> simuliereZufallsTipps({
    required int anzahlTipps,
    required String spieltyp,
    void Function(int current, int total)? onProgress,
  }) async {
    if (anzahlTipps <= 0) {
      throw ArgumentError('anzahlTipps muss > 0 sein');
    }

    final ziehungen = await ErweiterteLottoDatenbank.holeAlleZiehungen(
      spieltyp: spieltyp,
    );

    final rnd = Random();
    final aggTreffer = <int, int>{
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
      8: 0,
    };

    for (var i = 0; i < anzahlTipps; i++) {
      final zahlenSet = <int>{};
      while (zahlenSet.length < 6) {
        final zahl = rnd.nextInt(49) + 1; // 1..49
        zahlenSet.add(zahl);
      }
      final zahlen = zahlenSet.toList()..sort();
      final superzahl = rnd.nextInt(10); // 0..9

      final randomTipp = LottoZiehung(
        datum: DateTime(1900, 1, 1), // Dummy-Datum
        spieltyp: spieltyp,
        zahlen: zahlen,
        superzahl: superzahl,
      );

      final erg = _analysiereTippMitZiehungen(randomTipp, ziehungen);

      // Treffer pro Klasse aufsummieren
      aggTreffer.keys.forEach((klasse) {
        final wert = erg.trefferProKlasse[klasse] ?? 0;
        aggTreffer[klasse] = (aggTreffer[klasse] ?? 0) + wert;
      });

      if (onProgress != null) {
        onProgress(i + 1, anzahlTipps);
      }
    }

    // Durchschnitt berechnen
    final avg = <int, double>{};
    aggTreffer.forEach((klasse, sum) {
      avg[klasse] = sum / anzahlTipps;
    });

    return ZufallsSimulationErgebnis(
      anzahlTipps: anzahlTipps,
      durchschnittTrefferProKlasse: avg,
    );
  }

  // --------------------------------------------------------------------------
  // Interner Helfer: wertet einen Tipp gegen eine Liste von Ziehungen aus.
  // --------------------------------------------------------------------------
  WasWaereWennErgebnis _analysiereTippMitZiehungen(
    LottoZiehung tipp,
    List<LottoZiehung> ziehungen, {
    void Function(int current, int total)? onProgress,
  }) {
    final trefferProKlasse = <int, int>{
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
      8: 0,
    };

    DateTime? ersteTreffer;
    DateTime? letzteTreffer;
    var gesamtTrefferAbDrei = 0;

    final tipSet = tipp.zahlen.toSet();
    final total = ziehungen.length;

    for (var i = 0; i < ziehungen.length; i++) {
      final z = ziehungen[i];

      final ziehungsSet = z.zahlen.toSet();
      final richtige = tipSet.intersection(ziehungsSet).length;
      final szTreffer = (tipp.superzahl == z.superzahl);

      final klasse = _berechneGewinnklasse(richtige, szTreffer);
      if (klasse != null) {
        trefferProKlasse[klasse] = (trefferProKlasse[klasse] ?? 0) + 1;

        // nur Klassen mit mind. 3 Richtigen zählen wir als "Treffer"
        if (richtige >= 3) {
          gesamtTrefferAbDrei++;
          if (ersteTreffer == null || z.datum.isBefore(ersteTreffer)) {
            ersteTreffer = z.datum;
          }
          if (letzteTreffer == null || z.datum.isAfter(letzteTreffer)) {
            letzteTreffer = z.datum;
          }
        }
      }

      if (onProgress != null) {
        onProgress(i + 1, total);
      }
    }

    return WasWaereWennErgebnis(
      anzahlZiehungen: total,
      trefferProKlasse: trefferProKlasse,
      gesamtTrefferAbDrei: gesamtTrefferAbDrei,
      ersteTrefferZiehung: ersteTreffer,
      letzteTrefferZiehung: letzteTreffer,
    );
  }

  /// Gewinnklassen-Logik für LOTTO 6aus49.
  ///
  /// Rückgabe: 1..8 oder null, falls keine Gewinnklasse.
  int? _berechneGewinnklasse(int richtige, bool szTreffer) {
    if (richtige == 6 && szTreffer) return 1;  // 6+SZ
    if (richtige == 6 && !szTreffer) return 2; // 6
    if (richtige == 5 && szTreffer) return 3;  // 5+SZ
    if (richtige == 5 && !szTreffer) return 4; // 5
    if (richtige == 4 && szTreffer) return 5;  // 4+SZ
    if (richtige == 4 && !szTreffer) return 6; // 4
    if (richtige == 3 && szTreffer) return 7;  // 3+SZ
    if (richtige == 3 && !szTreffer) return 8; // 3
    return null;
  }
}
