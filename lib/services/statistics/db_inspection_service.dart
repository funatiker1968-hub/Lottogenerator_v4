import '../../models/lotto_data.dart';
import '../lotto_database_erweitert.dart';
import 'statistics_models.dart';

class DbInspectionService {
  Future<DbSummary> inspect({required String spieltyp}) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp: spieltyp);
    if (draws.isEmpty) {
      return DbSummary(spieltyp: spieltyp, count: 0, firstDate: null, lastDate: null);
    }
    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));
    return DbSummary(
      spieltyp: spieltyp,
      count: sorted.length,
      firstDate: sorted.first.datum,
      lastDate: sorted.last.datum,
    );
  }

  /// Findet Datums-Lücken: erwartet regelmäßige Ziehungen (EJ: Di+Fr, Lotto: Mi+Sa).
  /// Gibt Liste der "fehlenden" Datumswerte zurück (nur grob; kann Feiertage/Änderungen nicht kennen).
  Future<List<DateTime>> findMissingDates({
    required String spieltyp,
  }) async {
    final draws = await ErweiterteLottoDatenbank.holeAlleZiehungen(spieltyp: spieltyp);
    if (draws.length < 2) return [];

    final sorted = List<LottoZiehung>.from(draws)..sort((a, b) => a.datum.compareTo(b.datum));
    final dates = sorted.map((e) => DateTime(e.datum.year, e.datum.month, e.datum.day)).toSet();
    final first = DateTime(sorted.first.datum.year, sorted.first.datum.month, sorted.first.datum.day);
    final last = DateTime(sorted.last.datum.year, sorted.last.datum.month, sorted.last.datum.day);

    final expectedWeekdays = _expectedWeekdays(spieltyp);
    final missing = <DateTime>[];

    for (DateTime d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      if (!expectedWeekdays.contains(d.weekday)) continue;
      if (!dates.contains(DateTime(d.year, d.month, d.day))) {
        missing.add(d);
      }
    }
    return missing;
  }

  List<int> _expectedWeekdays(String spieltyp) {
    // Dart weekday: Mon=1..Sun=7
    if (spieltyp == '6aus49') {
      // Mittwoch(3) + Samstag(6)
      return [3, 6];
    }
    if (spieltyp == 'eurojackpot') {
      // Dienstag(2) + Freitag(5)
      return [2, 5];
    }
    // default: keine Annahme
    return [1, 2, 3, 4, 5, 6, 7];
  }
}
