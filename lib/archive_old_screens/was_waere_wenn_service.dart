import '../models/lotto_data.dart';
import '../services/lotto_database_erweitert.dart' as erweiterteDB;

class WasWaereWennTreffer {
  final DateTime datum;
  final int anzahlTreffer;
  final bool superzahlGetroffen;
  final List<int> getroffeneZahlen;

  WasWaereWennTreffer({
    required this.datum,
    required this.anzahlTreffer,
    required this.superzahlGetroffen,
    required this.getroffeneZahlen,
  });
}

class WasWaereWennErgebnis {
  final String spieltyp;
  final int anzahlZiehungen;
  final int tippGroesse;

  final int treffer3;
  final int treffer4;
  final int treffer5;
  final int treffer6;
  final int treffer6MitSuperzahl;

  /// Liste der besten Treffer (z.B. alle >= 4 Treffer)
  final List<WasWaereWennTreffer> topTreffer;

  WasWaereWennErgebnis({
    required this.spieltyp,
    required this.anzahlZiehungen,
    required this.tippGroesse,
    required this.treffer3,
    required this.treffer4,
    required this.treffer5,
    required this.treffer6,
    required this.treffer6MitSuperzahl,
    required this.topTreffer,
  });
}

/// B) Was-wäre-wenn-Analyse:
/// Prüft einen Tipp gegen historische Ziehungen.
class WasWaereWennService {
  /// Simuliert einen Tipp gegen die letzten [limitZiehungen] Ziehungen.
  /// [minTrefferForTopListe] steuert, ab wie vielen Treffern ein Eintrag in topTreffer aufgenommen wird.
  static Future<WasWaereWennErgebnis> simuliereTipp({
    required String spieltyp,
    required List<int> tippZahlen,
    int? superzahl,
    int? limitZiehungen,
    int minTrefferForTopListe = 4,
  }) async {
    final bereinigterTipp = tippZahlen
        .where((n) => n > 0)
        .toSet()
        .toList()
      ..sort();

    final ziehungen = await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
      spieltyp: spieltyp,
      limit: limitZiehungen ?? 2000,
    );

    if (ziehungen.isEmpty || bereinigterTipp.isEmpty) {
      return WasWaereWennErgebnis(
        spieltyp: spieltyp,
        anzahlZiehungen: ziehungen.length,
        tippGroesse: bereinigterTipp.length,
        treffer3: 0,
        treffer4: 0,
        treffer5: 0,
        treffer6: 0,
        treffer6MitSuperzahl: 0,
        topTreffer: const <WasWaereWennTreffer>[],
      );
    }

    int t3 = 0;
    int t4 = 0;
    int t5 = 0;
    int t6 = 0;
    int t6sz = 0;

    final top = <WasWaereWennTreffer>[];
    final tippSet = bereinigterTipp.toSet();

    for (final z in ziehungen) {
      final ziehungsSet = z.zahlen.toSet();
      final schnittmenge = tippSet.intersection(ziehungsSet).toList()..sort();
      final treffer = schnittmenge.length;
      final szHit = (superzahl != null) && (z.superzahl == superzahl);

      if (treffer >= 3) {
        if (treffer == 3) t3++;
        if (treffer == 4) t4++;
        if (treffer == 5) t5++;
        if (treffer == 6) {
          t6++;
          if (szHit) t6sz++;
        }
      }

      if (treffer >= minTrefferForTopListe) {
        top.add(
          WasWaereWennTreffer(
            datum: z.datum,
            anzahlTreffer: treffer,
            superzahlGetroffen: szHit,
            getroffeneZahlen: schnittmenge,
          ),
        );
      }
    }

    // Top-Treffer nach Anzahl Treffer absteigend sortieren
    top.sort((a, b) => b.anzahlTreffer.compareTo(a.anzahlTreffer));

    return WasWaereWennErgebnis(
      spieltyp: spieltyp,
      anzahlZiehungen: ziehungen.length,
      tippGroesse: bereinigterTipp.length,
      treffer3: t3,
      treffer4: t4,
      treffer5: t5,
      treffer6: t6,
      treffer6MitSuperzahl: t6sz,
      topTreffer: top,
    );
  }
}
