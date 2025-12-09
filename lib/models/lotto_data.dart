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
