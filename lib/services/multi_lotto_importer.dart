import '../services/lotto_database_erweitert.dart' as erweiterteDB;
import '../models/lotto_data.dart';

class MultiLottoImporter {
  Future<void> importiereJahresBereich(int startJahr, int endJahr) async {
    // Implementiere hier den Import-Logik
    // Beispiel:
    for (int jahr = startJahr; jahr <= endJahr; jahr++) {
      // Import-Logik für jedes Jahr
      print('Importiere Jahr: $jahr');
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  
  // Statt EinfacheLottoDatenbank, verwende erweiterteDB
  Future<List<LottoZiehung>> _holeDatenAusDatenbank(String spieltyp, int limit) async {
    return await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
      spieltyp: spieltyp,
      limit: limit,
    );
  }
}
