import 'frequency_service.dart';
import 'gap_service.dart';
import 'pair_service.dart';
import 'statistics_models.dart';

class EurojackpotStatisticsService {
  final FrequencyService _freq = FrequencyService();
  final GapService _gap = GapService();
  final PairService _pairs = PairService();

  Future<FrequencyResult> frequencyMain({int lastN = 0}) {
    return _freq.frequency(
      spieltyp: 'eurojackpot',
      lastNDraws: lastN,
      takeNumbersPerDraw: 5,
      euroOffset: 0,
    );
  }

  Future<FrequencyResult> frequencyEuro({int lastN = 0}) {
    return _freq.frequency(
      spieltyp: 'eurojackpot',
      lastNDraws: lastN,
      takeNumbersPerDraw: 2,
      euroOffset: 5,
    );
  }

  Future<List<GapStats>> gapsMain() {
    return _gap.gaps(
      spieltyp: 'eurojackpot',
      minNumber: 1,
      maxNumber: 50,
      takeNumbersPerDraw: 5,
      euroOffset: 0,
    );
  }

  Future<List<GapStats>> gapsEuro() {
    return _gap.gaps(
      spieltyp: 'eurojackpot',
      minNumber: 1,
      maxNumber: 12,
      takeNumbersPerDraw: 2,
      euroOffset: 5,
    );
  }

  Future<PairResult> pairMain() {
    return _pairs.pairs(spieltyp: 'eurojackpot', takeNumbersPerDraw: 5, euroOffset: 0);
  }

  Future<PairResult> pairEuro() {
    return _pairs.pairs(spieltyp: 'eurojackpot', takeNumbersPerDraw: 2, euroOffset: 5);
  }
}
