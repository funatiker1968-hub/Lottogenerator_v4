class LottoDraw {
  final String spieltyp; // "6aus49" | "eurojackpot"
  final DateTime datum;
  final List<int> zahlen; // sortiert, ohne Superzahl
  final int? superzahl; // nur bei 6aus49, sonst null

  const LottoDraw({
    required this.spieltyp,
    required this.datum,
    required this.zahlen,
    this.superzahl,
  });
}
