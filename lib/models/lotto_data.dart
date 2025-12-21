import 'dart:convert';

class LottoZiehung {
  final DateTime datum;
  final List<int> zahlen;
  final int superzahl;
  final String spieltyp;

  LottoZiehung({
    required this.datum,
    required this.zahlen,
    required this.superzahl,
    required this.spieltyp,
  });

  // Factory-Methode zum Erstellen aus einer Datenbank-Map
  factory LottoZiehung.fromMap(Map<String, dynamic> map) {
    return LottoZiehung(
      spieltyp: map['spieltyp'],
      datum: DateTime.parse(map['datum']),
      zahlen: List<int>.from(json.decode(map['zahlen'])),
      superzahl: map['superzahl'],
    );
  }

  // Methode zum Konvertieren in Map für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'spieltyp': spieltyp,
      'datum': datum.toIso8601String(),
      'zahlen': json.encode(zahlen),
      'superzahl': superzahl,
    };
  }

  String get formatierterDatum =>
      '${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.${datum.year}';

  static DateTime parseDatum(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9\.]'), '');
    final t = clean.split('.');
    if (t.length >= 3) {
      return DateTime(int.parse(t[2]), int.parse(t[1]), int.parse(t[0]));
    }
    return DateTime.now();
  }
}
