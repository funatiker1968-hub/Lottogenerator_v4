import 'package:http/http.dart' as http;
import '../models/lotto_data.dart';

class LottoApiImporter {
  Future<List<LottoZiehung>> importiereVonLottoAPI({
    required String spieltyp,
    int jahr = 2024,
    int limit = 100,
  }) async {
    final url = Uri.parse(
        'https://www.lotto.de/api/stats/gewinnzahlen?jahr=$jahr&limit=$limit');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Hier müsste der API-Response geparsed werden
        // Dies ist ein Beispiel - passe es an deine API-Struktur an
        return _parseApiResponse(response.body, spieltyp);
      } else {
        throw Exception('API Request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Fehler beim API-Import: $e');
      return [];
    }
  }

  List<LottoZiehung> _parseApiResponse(String body, String spieltyp) {
    // Hier den API-Response parsen
    // Dies ist nur ein Beispiel - passe es an deine API an
    final ziehungen = <LottoZiehung>[];
    
    // Beispiel-Parsing (muss an deine API angepasst werden)
    try {
      // Angenommen, die API gibt JSON zurück
      // final data = jsonDecode(body);
      // for (final item in data['ziehungen']) {
      //   ziehungen.add(LottoZiehung(
      //     datum: DateTime.parse(item['date']),
      //     zahlen: List<int>.from(item['numbers']),
      //     superzahl: item['superzahl'],
      //     spieltyp: spieltyp,
      //   ));
      // }
    } catch (e) {
      print('Fehler beim Parsen der API-Antwort: $e');
    }
    
    return ziehungen;
  }
}
