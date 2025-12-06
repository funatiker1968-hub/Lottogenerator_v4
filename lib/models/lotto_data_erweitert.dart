import 'lotto_data.dart';

// Erweiterung für LottoZiehung
extension LottoZiehungErweiterung on LottoZiehung {
  List<int> get alleZahlen {
    return [...zahlen]; // Bei 6aus49 sind alle 6 Zahlen Hauptzahlen
  }
  
  List<int> get euroHauptzahlen {
    if (spieltyp == 'Eurojackpot' && zahlen.length >= 5) {
      return zahlen.sublist(0, 5);
    }
    return zahlen;
  }
  
  List<int> get euroZusatzzahlen {
    if (spieltyp == 'Eurojackpot' && zahlen.length >= 7) {
      return zahlen.sublist(5, 7);
    }
    return [];
  }
}
