class LottoDraw {
  final DateTime date;
  final List<int> numbers;
  final int extra; // Superzahl (Lotto) oder -1 wenn nicht vorhanden

  LottoDraw({
    required this.date,
    required this.numbers,
    required this.extra,
  });

  @override
  String toString() {
    return 'LottoDraw(date: $date, numbers: $numbers, extra: $extra)';
  }
}
