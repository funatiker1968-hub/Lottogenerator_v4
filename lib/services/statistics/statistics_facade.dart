import 'db_inspection_service.dart';
import 'frequency_service.dart';
import 'gap_service.dart';
import 'pair_service.dart';
import 'cluster_service.dart';
import 'sum_service.dart';
import 'parity_service.dart';
import 'eurojackpot_statistics_service.dart';
import 'simulation_service.dart';
import 'generator_service.dart';

class StatisticsFacade {
  final DbInspectionService _db = DbInspectionService();
  final FrequencyService _freq = FrequencyService();
  final GapService _gap = GapService();
  final PairService _pair = PairService();
  final ClusterService _cluster = ClusterService();
  final SumService _sum = SumService();
  final ParityService _parity = ParityService();
  final SimulationService _sim = SimulationService();
  final GeneratorService _gen = GeneratorService();
  
  // Eurojackpot Service
  final EurojackpotStatisticsService ej = EurojackpotStatisticsService();

  Future<DbSummary> dbSummary({required String spieltyp}) => _db.dbSummary(spieltyp: spieltyp);
  
  Future<FrequencyResult> frequencyMain({String spieltyp = '6aus49', int lastNDraws = 0}) => 
      _freq.frequency(spieltyp: spieltyp, lastNDraws: lastNDraws);
  
  Future<FrequencyResult> frequencySuper({int lastNDraws = 0}) => 
      _freq.frequency(spieltyp: '6aus49', lastNDraws: lastNDraws, superzahl: true);
  
  Future<List<GapStats>> gaps({String spieltyp = '6aus49'}) => 
      _gap.gaps(spieltyp: spieltyp);
  
  Future<PairResult> pairs({String spieltyp = '6aus49'}) => 
      _pair.pairs(spieltyp: spieltyp);
  
  Future<RangeDistribution> rangeDistribution({String spieltyp = '6aus49'}) => 
      _cluster.distribution(spieltyp: spieltyp, buckets: _defaultLottoBuckets());
  
  Future<SumStats> sumStats({String spieltyp = '6aus49'}) => 
      _sum.sumStats(spieltyp: spieltyp);
  
  Future<Map<String, int>> parity({String spieltyp = '6aus49'}) => 
      _parity.parity(spieltyp: spieltyp);
  
  List<RangeBucket> defaultLottoBuckets() => _defaultLottoBuckets();
  
  List<RangeBucket> _defaultLottoBuckets() {
    return [
      RangeBucket('1-10', 1, 10),
      RangeBucket('11-20', 11, 20),
      RangeBucket('21-30', 21, 30),
      RangeBucket('31-40', 31, 40),
      RangeBucket('41-49', 41, 49),
    ];
  }
}
