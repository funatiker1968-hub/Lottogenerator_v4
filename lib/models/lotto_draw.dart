class LottoDraw {
  final DateTime date;
  final List<int> numbers; // 6 bei Lotto, 5+2 bei Eurojackpot
  final int superzahl; // Lotto: -1, 0–9 | Eurojackpot: immer -1

  LottoDraw({
    required this.date,
    required this.numbers,
    required this.superzahl,
  });
}
