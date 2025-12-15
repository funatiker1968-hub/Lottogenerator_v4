// ignore_for_file: avoid_print
import 'statistics.dart';

class StatisticsDebugRunner {
  final StatisticsFacade stats = StatisticsFacade();

  Future<void> runAll() async {
    await _dbInfo();
    await _frequency();
    await _gaps();
    await _parity();
    await _clusters();
    await _sums();
    await _pairs();
    await _simulation();
    await _generator();
  }

  Future<void> _dbInfo() async {
    final lotto = await stats.db.inspect(spieltyp: '6aus49');
    final ej = await stats.db.inspect(spieltyp: 'eurojackpot');

    print('DB Lotto: $lotto');
    print('DB EJ   : $ej');
  }

  Future<void> _frequency() async {
    final f = await stats.freq.frequency(
      spieltyp: '6aus49',
      takeNumbersPerDraw: 6,
    );
    print('Top 6 Lotto: ${f.top(6)}');
    print('Cold 6 Lotto: ${f.bottom(6)}');
  }

  Future<void> _gaps() async {
    final gaps = await stats.gap.gaps(
      spieltyp: '6aus49',
      minNumber: 1,
      maxNumber: 49,
      takeNumbersPerDraw: 6,
    );
    print('Most overdue Lotto: ${gaps.take(5).toList()}');
  }

  Future<void> _parity() async {
    final hist = await stats.parity.parityHistogram(
      spieltyp: '6aus49',
      takeNumbersPerDraw: 6,
    );
    print('Parity histogram Lotto: $hist');
  }

  Future<void> _clusters() async {
    final dist = await stats.cluster.distribution(
      spieltyp: '6aus49',
      buckets: stats.defaultLottoBuckets(),
      takeNumbersPerDraw: 6,
    );
    print('Cluster distribution Lotto: ${dist.counts}');
  }

  Future<void> _sums() async {
    final s = await stats.sums.sumStats(
      spieltyp: '6aus49',
      takeNumbersPerDraw: 6,
    );
    print('Sum stats Lotto: min=${s.minSum} max=${s.maxSum} avg=${s.avgSum}');
  }

  Future<void> _pairs() async {
    final p = await stats.pairs.pairs(
      spieltyp: '6aus49',
      takeNumbersPerDraw: 6,
    );
    print('Top pairs Lotto: ${p.top(5)}');
  }

  Future<void> _simulation() async {
    final sim = await stats.sim.simulateLotto6aus49(
      tipMain: [1, 7, 13, 25, 33, 49],
      superzahl: 7,
    );
    print('Simulation Lotto: ${sim.histogram}');
  }

  Future<void> _generator() async {
    final tip = await stats.gen.generateLotto6aus49();
    final ej = await stats.gen.generateEurojackpot();

    print('Generated Lotto tip: ${tip.numbers}');
    print('Generated EJ tip   : ${ej.numbers}');
  }
}
