// Einfache Daten-Klasse für Lotto-Ziehungen
class LottoZiehung {
  final DateTime datum;
  final List<int> zahlen;
  final int superzahl;
  final String spieltyp;

  LottoZiehung({
    required this.datum,
    required this.zahlen,
    required this.superzahl,
    this.spieltyp = '6aus49',
  });

  // Einfache Formatierung
  String get formatierteZahlen {
    return zahlen.map((z) => z.toString().padLeft(2, '0')).join(', ');
  }
  
  String get formatierterDatum {
    return '${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.${datum.year}';
  }
}

// Beispiel-Daten für den Anfang
class BeispielDaten {
  static List<LottoZiehung> get beispielZiehungen {
    return [
      LottoZiehung(
        datum: DateTime(2024, 1, 6),
        zahlen: [3, 7, 12, 25, 34, 42],
        superzahl: 8,
      ),
      LottoZiehung(
        datum: DateTime(2024, 1, 13),
        zahlen: [5, 11, 19, 23, 37, 45],
        superzahl: 2,
      ),
      LottoZiehung(
        datum: DateTime(2024, 1, 20),
        zahlen: [2, 9, 17, 28, 31, 44],
        superzahl: 6,
      ),
      LottoZiehung(
        datum: DateTime(2024, 1, 27),
        zahlen: [8, 14, 21, 29, 36, 49],
        superzahl: 3,
      ),
      LottoZiehung(
        datum: DateTime(2024, 2, 3),
        zahlen: [1, 10, 18, 27, 33, 46],
        superzahl: 9,
      ),
    ];
  }
}
