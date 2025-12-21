import 'cluster_service.dart';
import 'db_inspection_service.dart';
import 'eurojackpot_statistics_service.dart';
import 'frequency_service.dart';
import 'gap_service.dart';
import 'generator_service.dart';
import 'pair_service.dart';
import 'parity_service.dart';
import 'simulation_service.dart';
import 'sum_service.dart';
import 'statistics_models.dart';

class StatisticsFacade {
  final DbInspectionService db = DbInspectionService();
  final FrequencyService freq = FrequencyService();
  final GapService gap = GapService();
  final ParityService parity = ParityService();
  final ClusterService cluster = ClusterService();
  final SumService sums = SumService();
  final PairService pairs = PairService();
  final EurojackpotStatisticsService ej = EurojackpotStatisticsService();
  final SimulationService sim = SimulationService();
  final GeneratorService gen = GeneratorService();

  List<RangeBucket> defaultLottoBuckets() => const [
        RangeBucket('1-12', 1, 12),
        RangeBucket('13-25', 13, 25),
        RangeBucket('26-38', 26, 38),
        RangeBucket('39-49', 39, 49),
      ];
}
