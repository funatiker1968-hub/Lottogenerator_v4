import '../services/lottozahlenonline_scraper.dart';
import '../services/lotto_database_erweitert.dart';
import '../models/lotto_data.dart';

class LottoImportService {
  /// Importiert echte Ziehungen eines Jahres
  /// Fortschritt wird durch callback ausgegeben
  Future<void> importJahr({
    required int jahr,
    required String spieltyp,
    required void Function(String msg) status,
  }) async {
    status("Lade Daten für $spieltyp – Jahr $jahr …");

    final scraper = LottozahlenOnlineScraper(spieltyp);

    final ziehungen = await scraper.ladeJahr(jahr);
    if (ziehungen == null || ziehungen.isEmpty) {
      status("⚠️ Keine Daten gefunden für $jahr ($spieltyp)");
      return;
    }

    int neu = 0;
    int doppelt = 0;

    for (final z in ziehungen) {
      final existiert = await ErweiterteLottoDatenbank.pruefeObSchonVorhanden(
        spieltyp,
        z.datum,
      );

      if (existiert) {
        doppelt++;
      } else {
        await ErweiterteLottoDatenbank.fuegeZiehungWennNeu(z);
        neu++;
      }

      status("Verarbeite ${z.datum} – neu: $neu | doppelt: $doppelt");
    }

    status("✔️ Jahr $jahr abgeschlossen: neu=$neu | doppelt=$doppelt");
  }

  /// Importiert alle Jahre von Start–Ende
  Future<void> importBereich({
    required int start,
    required int ende,
    required String spieltyp,
    required void Function(String msg) status,
  }) async {
    if (ende < start) {
      status("Fehler: Endjahr < Startjahr");
      return;
    }

    for (int jahr = start; jahr <= ende; jahr++) {
      await importJahr(jahr: jahr, spieltyp: spieltyp, status: status);
    }

    status("🎉 Importvorgang abgeschlossen!");
  }
}
