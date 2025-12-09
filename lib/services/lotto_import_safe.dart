import '../models/lotto_data.dart';
import 'lotto_database_erweitert.dart';

class LottoImportSafe {
  Future<void> fuegeZiehungenEin(List<LottoZiehung> ziehungen) async {
    await ErweiterteLottoDatenbank.fuegeZiehungenHinzu(ziehungen);
  }
}
