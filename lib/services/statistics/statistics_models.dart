import 'package:flutter/foundation.dart';

@immutable
class DbSummary {
  final String spieltyp;
  final int count;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DbSummary({
    required this.spieltyp,
    required this.count,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  String toString() => 'DbSummary($spieltyp count=$count first=$firstDate last=$lastDate)';
}

@immutable
class FrequencyResult {
  final String spieltyp;
  final Map<int, int> counts; // number -> frequency
  final int totalDraws;
  final int numbersPerDraw;

  const FrequencyResult({
    required this.spieltyp,
    required this.counts,
    required this.totalDraws,
    required this.numbersPerDraw,
  });

  List<MapEntry<int, int>> top(int n) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }

  List<MapEntry<int, int>> bottom(int n) {
    final entries = counts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(n).toList();
  }
}

@immutable
class GapStats {
  final int number;
  final int occurrences;
  final int? minGap; // in draws
  final int? maxGap; // in draws
  final double? avgGap; // in draws
  final int currentGap; // draws since last occurrence (if never: large)

  const GapStats({
    required this.number,
    required this.occurrences,
    required this.minGap,
    required this.maxGap,
    required this.avgGap,
    required this.currentGap,
  });
}

@immutable
class ParityStats {
  final int even;
  final int odd;

  const ParityStats({required this.even, required this.odd});

  @override
  String toString() => 'Parity(even=$even odd=$odd)';
}

@immutable
class RangeBucket {
  final String label;
  final int fromInclusive;
  final int toInclusive;

  const RangeBucket(this.label, this.fromInclusive, this.toInclusive);

  bool contains(int n) => n >= fromInclusive && n <= toInclusive;
}

@immutable
class RangeDistribution {
  final String spieltyp;
  final List<RangeBucket> buckets;
  final Map<String, int> counts; // label -> count across all numbers (not draws)

  const RangeDistribution({
    required this.spieltyp,
    required this.buckets,
    required this.counts,
  });
}

@immutable
class SumStats {
  final String spieltyp;
  final int countDraws;
  final int minSum;
  final int maxSum;
  final double avgSum;

  const SumStats({
    required this.spieltyp,
    required this.countDraws,
    required this.minSum,
    required this.maxSum,
    required this.avgSum,
  });
}

@immutable
class PairKey {
  final int a;
  final int b;

  const PairKey(this.a, this.b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PairKey && runtimeType == other.runtimeType && a == other.a && b == other.b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => '($a,$b)';
}

@immutable
class PairResult {
  final String spieltyp;
  final Map<PairKey, int> counts;

  const PairResult({required this.spieltyp, required this.counts});

  List<MapEntry<PairKey, int>> top(int n) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }
}

@immutable
class SimulationRow {
  final DateTime date;
  final int hitsMain; // how many main numbers matched
  final int hitsExtra; // superzahl/eurozahlen matched (optional meaning)
  const SimulationRow({required this.date, required this.hitsMain, required this.hitsExtra});
}

@immutable
class SimulationSummary {
  final String spieltyp;
  final int draws;
  final Map<String, int> histogram; // e.g. "3" -> 120, "4+SZ" -> 5 etc.

  const SimulationSummary({
    required this.spieltyp,
    required this.draws,
    required this.histogram,
  });
}

@immutable
class GeneratedTip {
  final String spieltyp;
  final List<int> numbers; // lotto: 6 + superzahl(1) optional? EJ: 5+2
  const GeneratedTip({required this.spieltyp, required this.numbers});
}
