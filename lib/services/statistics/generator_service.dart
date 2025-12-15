import 'dart:math';
import 'frequency_service.dart';
import 'statistics_models.dart';

class GeneratorService {
  final Random _rng = Random();
  final FrequencyService _freq = FrequencyService();

  /// Gewichteter Generator über Häufigkeiten (Hot bias).
  /// bias=1.0 -> neutral, bias>1 -> hot stärker, bias<1 -> cold stärker
  Future<GeneratedTip> generateLotto6aus49({
    int lastN = 0,
    double bias = 1.25,
    bool includeSuperzahl = true,
  }) async {
    final fr = await _freq.frequency(
      spieltyp: '6aus49',
      lastNDraws: lastN,
      takeNumbersPerDraw: 6,
      euroOffset: 0,
    );

    final chosen = _weightedUnique(
      candidates: List.generate(49, (i) => i + 1),
      weights: (n) => _weightFromCount(fr, n, bias),
      k: 6,
    )..sort();

    if (!includeSuperzahl) {
      return GeneratedTip(spieltyp: '6aus49', numbers: chosen);
    }
    final sz = _rng.nextInt(10);
    return GeneratedTip(spieltyp: '6aus49', numbers: [...chosen, sz]);
  }

  Future<GeneratedTip> generateEurojackpot({
    int lastN = 0,
    double biasMain = 1.20,
    double biasEuro = 1.10,
  }) async {
    final main = await _freq.frequency(
      spieltyp: 'eurojackpot',
      lastNDraws: lastN,
      takeNumbersPerDraw: 5,
      euroOffset: 0,
    );
    final euro = await _freq.frequency(
      spieltyp: 'eurojackpot',
      lastNDraws: lastN,
      takeNumbersPerDraw: 2,
      euroOffset: 5,
    );

    final mainNums = _weightedUnique(
      candidates: List.generate(50, (i) => i + 1),
      weights: (n) => _weightFromCount(main, n, biasMain),
      k: 5,
    )..sort();

    final euroNums = _weightedUnique(
      candidates: List.generate(12, (i) => i + 1),
      weights: (n) => _weightFromCount(euro, n, biasEuro),
      k: 2,
    )..sort();

    return GeneratedTip(spieltyp: 'eurojackpot', numbers: [...mainNums, ...euroNums]);
  }

  double _weightFromCount(FrequencyResult fr, int n, double bias) {
    // Basis: 1.0 + count
    final c = fr.counts[n] ?? 0;
    final base = 1.0 + c.toDouble();
    // bias exponent
    return pow(base, bias).toDouble();
  }

  List<int> _weightedUnique({
    required List<int> candidates,
    required double Function(int n) weights,
    required int k,
  }) {
    final chosen = <int>{};

    // precompute weights
    final w = <int, double>{ for (final n in candidates) n: weights(n) };
    final total = w.values.fold<double>(0, (p, e) => p + e);

    int guard = 0;
    while (chosen.length < k && guard < 100000) {
      guard++;
      final pick = _roulette(candidates, w, total);
      chosen.add(pick);
    }
    return chosen.toList();
  }

  int _roulette(List<int> candidates, Map<int, double> w, double total) {
    final r = _rng.nextDouble() * total;
    double acc = 0;
    for (final n in candidates) {
      acc += (w[n] ?? 0);
      if (acc >= r) return n;
    }
    return candidates.last;
  }
}
