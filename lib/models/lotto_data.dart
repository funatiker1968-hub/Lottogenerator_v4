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

  // Factory-Methode: Konvertiert DB-String zurück zu Zahlen-Liste
  factory LottoZiehung.fromMap(Map<String, dynamic> map) {
    final dateStr = map['datum'] as String;
    
    // 1. DATUM parsen (unterstützt ISO und DD.MM.YYYY)
    DateTime datum;
    if (dateStr.contains('-')) {
      // ISO-Format: 1956-01-01
      datum = DateTime.parse(dateStr);
    } else {
      // DD.MM.YYYY Format
      final parts = dateStr.split('.');
      datum = DateTime(
        int.parse(parts[2]),  // Jahr
        int.parse(parts[1]),  // Monat
        int.parse(parts[0]),  // Tag
      );
    }
    
    // 2. ZAHLEN parsen (entweder "4 22 27 36 38 46" oder "[4,22,27,36,38,46]")
    final zahlenRaw = map['zahlen'] as String;
    List<int> zahlen;
    
    if (zahlenRaw.startsWith('[') && zahlenRaw.endsWith(']')) {
      // JSON-Format: als Array decodieren
      zahlen = List<int>.from(json.decode(zahlenRaw));
    } else {
      // Plain-Text Format: Leerzeichen-getrennt
      zahlen = zahlenRaw
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList();
    }
    
    return LottoZiehung(
      spieltyp: map['spieltyp'],
      datum: datum,
      zahlen: zahlen,
      superzahl: map['superzahl'],
    );
  }

  // toMap(): Konvertiert für DB-Speicherung
  Map<String, dynamic> toMap() {
    // WICHTIG: Zahlen als LEERZEICHEN-getrennten String speichern
    // NICHT als JSON, da das unser TXT-Format entspricht
    final zahlenString = zahlen.join(' ');
    
    return {
      'spieltyp': spieltyp,
      'datum': datum.toIso8601String(), // Immer ISO speichern
      'zahlen': zahlenString,           // "4 22 27 36 38 46"
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
