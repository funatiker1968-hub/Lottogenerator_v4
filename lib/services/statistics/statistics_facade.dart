import 'db_inspection_service.dart';
import 'frequency_service.dart';
import 'gap_service.dart';
import 'pair_service.dart';
import 'cluster_service.dart';
import 'sum_service.dart';
import 'parity_service.dart';
import 'eurojackpot_statistics_service.dart';
import 'statistics_models.dart';

class StatisticsFacade {
  final DbInspectionService _db = DbInspectionService();
  final FrequencyService _freq = FrequencyService();
  final GapService _gap = GapService();
  final PairService _pair = PairService();
  final ClusterService _cluster = ClusterService();
  final SumService _sum = SumService();
  final ParityService _parity = ParityService();
  
  // Eurojackpot Service
  final EurojackpotStatisticsService ej = EurojackpotStatisticsService();

  Future<DbSummary> dbSummary({required String spieltyp}) => 
      _db.dbSummary(spieltyp: spieltyp);

  Future<FrequencyResult> frequencyMain({
    String spieltyp = '6aus49',
    int lastNDraws = 0,
  }) => _freq.frequency(
    spieltyp: spieltyp,
    lastNDraws: lastNDraws,
    takeNumbersPerDraw: spieltyp == '6aus49' ? 6 : 5,
    euroOffset: 0,
  );

  Future<FrequencyResult> frequencySuper({int lastNDraws = 0}) => 
      _freq.frequency(
        spieltyp: '6aus49',
        lastNDraws: lastNDraws,
        superzahl: true,
        takeNumbersPerDraw: 1,
        euroOffset: 6,
      );

  Future<List<GapStats>> gaps({
    String spieltyp = '6aus49',
    int lastNDraws = 0,
  }) => _gap.gaps(
    spieltyp: spieltyp,
    lastNDraws: lastNDraws,
    minNumber: spieltyp == '6aus49' ? 1 : 1,
    maxNumber: spieltyp == '6aus49' ? 49 : 50,
    takeNumbersPerDraw: spieltyp == '6aus49' ? 6 : 5,
    euroOffset: 0,
  );

  Future<PairResult> pairs({String spieltyp = '6aus49'}) => 
      _pair.pairs(spieltyp: spieltyp);

  Future<RangeDistribution> rangeDistribution({
    String spieltyp = '6aus49',
    List<RangeBucket>? buckets,
  }) => _cluster.distribution(
    spieltyp: spieltyp,
    buckets: buckets ?? (spieltyp == '6aus49' ? _defaultLottoBuckets() : _defaultEurojackpotBuckets()),
    takeNumbersPerDraw: spieltyp == '6aus49' ? 6 : 5,
    euroOffset: 0,
  );

  Future<SumStats> sumStats({
    String spieltyp = '6aus49',
  }) => _sum.sumStats(
    spieltyp: spieltyp,
    takeNumbersPerDraw: spieltyp == '6aus49' ? 6 : 5,
    euroOffset: 0,
  );

  Future<Map<String, int>> parity({
    String spieltyp = '6aus49',
  }) => _parity.parity(
    spieltyp: spieltyp,
    takeNumbersPerDraw: spieltyp == '6aus49' ? 6 : 5,
    euroOffset: 0,
  );

  List<RangeBucket> defaultLottoBuckets() => _defaultLottoBuckets();
  
  List<RangeBucket> defaultEurojackpotBuckets() => _defaultEurojackpotBuckets();

  List<RangeBucket> _defaultLottoBuckets() {
    return [
      const RangeBucket('1-10', 1, 10),
      const RangeBucket('11-20', 11, 20),
      const RangeBucket('21-30', 21, 30),
      const RangeBucket('31-40', 31, 40),
      const RangeBucket('41-49', 41, 49),
    ];
  }

  List<RangeBucket> _defaultEurojackpotBuckets() {
    return [
      const RangeBucket('1-10', 1, 10),
      const RangeBucket('11-20', 11, 20),
      const RangeBucket('21-30', 21, 30),
      const RangeBucket('31-40', 31, 40),
      const RangeBucket('41-50', 41, 50),
    ];
  }
}
