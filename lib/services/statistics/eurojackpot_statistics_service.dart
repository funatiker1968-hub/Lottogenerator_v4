import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'frequency_service.dart';
import 'gap_service.dart';
import 'pair_service.dart';
import 'statistics_models.dart';

class EurojackpotStatisticsService {
  final LottoDatabase db = LottoDatabase();
  final FrequencyService _freq = FrequencyService();
  final GapService _gap = GapService();
  final PairService _pair = PairService();

  Future<FrequencyResult> frequencyMain() async {
    return await _freq.frequency(
      spieltyp: 'eurojackpot',
      takeNumbersPerDraw: 5,
      euroOffset: 0,
    );
  }

  Future<FrequencyResult> frequencyEuro() async {
    return await _freq.frequency(
      spieltyp: 'eurojackpot',
      takeNumbersPerDraw: 2,
      euroOffset: 5, // Eurozahlen sind ab Index 5 (nach 5 Hauptzahlen)
    );
  }

  Future<List<GapStats>> gapsMain() async {
    return await _gap.gaps(
      spieltyp: 'eurojackpot',
      minNumber: 1,
      maxNumber: 50,
      takeNumbersPerDraw: 5,
      euroOffset: 0,
    );
  }

  Future<List<GapStats>> gapsEuro() async {
    return await _gap.gaps(
      spieltyp: 'eurojackpot',
      minNumber: 1,
      maxNumber: 12,
      takeNumbersPerDraw: 2,
      euroOffset: 5,
    );
  }

  Future<PairResult> pairMain() async {
    return await _pair.pairs(
      spieltyp: 'eurojackpot',
      takeNumbersPerDraw: 5,
      euroOffset: 0,
    );
  }

  Future<PairResult> pairEuro() async {
    return await _pair.pairs(
      spieltyp: 'eurojackpot',
      takeNumbersPerDraw: 2,
      euroOffset: 5,
    );
  }
}
