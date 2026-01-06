class StatisticsService {
  static Map<int, int> countNumbers(List<Map<String, dynamic>> entries) {
    final Map<int, int> counter = {};
    for (final e in entries) {
      final List<int> nums = List<int>.from(e['numbers']);
      for (final n in nums) {
        counter[n] = (counter[n] ?? 0) + 1;
      }
    }
    return counter;
  }

  static List<MapEntry<int, int>> topNumbers(
    List<Map<String, dynamic>> entries, {
    int limit = 10,
  }) {
    final counts = countNumbers(entries);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  static List<Map<String, dynamic>> lastDraws(
    List<Map<String, dynamic>> entries, {
    int limit = 2,
  }) {
    final sorted = List<Map<String, dynamic>>.from(entries)
      ..sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return sorted.take(limit).toList();
  }
}
