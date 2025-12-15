// ignore_for_file: unused_element
// BLOCK 1: IMPORTS & ROOT WIDGET
// ============================================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

// ============================================================================
// BLOCK 2: STATE – FELDER & HILFSFUNKTIONEN
// ============================================================================
class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int maxMarksPerTipNormal = 6;

  /// System-Modus je Tipp:
  /// 0 = Normalschein, 7..12 = System 7..12
  late final List<int> _systemMode;

  /// Tipps – gewählte Zahlen pro Tippfeld
  late final List<Set<int>> _selectedPerTip;

  /// Favoriten je Tippfeld (Subset von _selectedPerTip)
  late final List<Set<int>> _favoritePerTip;

  /// Zusatzlotterien
  bool _spiel77 = false;
  bool _super6 = false;
  bool _gluecksspirale = false;

  /// Ziehungstage: 0 = Mi, 1 = Sa, 2 = Mi+Sa
  int _ziehungstage = 0;

  /// Laufzeit (Wochen)
  int _laufzeitWochen = 1;

  /// Losnummer (7-stellig)
  late String _losnummer;

  /// Seed, damit die Walzen-Animation neu getriggert wird
  int _losAnimationSeed = 0;

  final Random _rng = Random();

  /// System-Reihen pro Systemtyp (echte 6aus49-Kombinationen)
  /// 0 = Normal (1 Reihe), 7 = 7 Reihen, 8 = 28, 9 = 84, 10 = 210, 11 = 462, 12 = 924
  static const Map<int, int> _systemReihen = {
    0: 1, // Normal
    7: 7,
    8: 28,
    9: 84,
    10: 210,
    11: 462,
    12: 924,
  };

  @override
  void initState() {
    super.initState();
    _selectedPerTip = List.generate(tipCount, (_) => <int>{});
    _favoritePerTip = List.generate(tipCount, (_) => <int>{});
    _systemMode = List<int>.filled(tipCount, 0); // alle erstmal Normalschein
    _generateNewLosnummer();
  }

  void _generateNewLosnummer() {
    _losnummer = List.generate(7, (_) => _rng.nextInt(10)).join();
    // Seed erhöhen, damit die Walzen-Animation neu startet
    _losAnimationSeed++;
  }

  int _maxMarksForTip(int tipIndex) {
    final mode = _systemMode[tipIndex];
    if (mode == 0) {
      return maxMarksPerTipNormal;
    }
    // System N → max N Zahlen
    return mode;
  }

  int _rowsForTip(int tipIndex) {
    final mode = _systemMode[tipIndex];
    return _systemReihen[mode] ?? 1;
  }

  // aktuell nicht verwendet, aber behalten für evtl. spätere Features
  int _activeTipCount() {
    return _selectedPerTip.where((s) => s.isNotEmpty).length;
  }

// ========================================================================
// BLOCK 3: BUILD + HEADER
// ========================================================================
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFF6C0),
    body: SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          // Alles unter dem Header ist zoombar + scrollbar
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.6,
              maxScale: 2.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: _buildScheinMitFooterUndLeiste(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildHeader() {
  return Container(
    height: 56,
    width: double.infinity,
    color: const Color(0xFFFFD000),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.centerLeft,
    child: const Text(
      'LOTTOZAHLEN-GENERATOR',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.red,
      ),
    ),
  );
 }
// Kompletter Scheinbereich: Tippfelder + Info-Boxen + Quicktipp-Leiste
Widget _buildScheinMitFooterUndLeiste() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildFullSchein(),       // deine 12 Tippfelder
      const SizedBox(height: 8),
      _buildBottomBar(),        // Losnummer + Zusatzspiele + Ziehung + Einsatz
      const SizedBox(height: 6),
      _buildQuickBar(),         // Quicktipp + Löschen
    ],
  );
}

  // ========================================================================
  // BLOCK 4: GESAMTER LOTTO-SCHEIN + TIPP-KARTEN
  // ========================================================================
  Widget _buildFullSchein() {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCE8),
            border: Border.all(color: Colors.red.shade700, width: 1.6),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildTipCard(i + 1),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildTipCard(i + 7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// EIN TIPP MIT:
  /// - Dropdown (Normal/System7–12)
  /// - Raster 1–49
  /// - Kugelleiste unten (Favoriten rot, andere blau)
  Widget _buildTipCard(int tipNumber) {
    final int tipIndex = tipNumber - 1;
    final int mode = _systemMode[tipIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red.shade700, width: 1.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Kopfzeile: "Tipp X" + Dropdown (Normal / System 7–12)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.red.shade700, width: 1.4),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Tipp $tipNumber',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: mode,
                    isDense: true,
                    iconSize: 16,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.black,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Normal'),
                      ),
                      DropdownMenuItem(
                        value: 7,
                        child: Text('System 7'),
                      ),
                      DropdownMenuItem(
                        value: 8,
                        child: Text('System 8'),
                      ),
                      DropdownMenuItem(
                        value: 9,
                        child: Text('System 9'),
                      ),
                      DropdownMenuItem(
                        value: 10,
                        child: Text('System 10'),
                      ),
                      DropdownMenuItem(
                        value: 11,
                        child: Text('System 11'),
                      ),
                      DropdownMenuItem(
                        value: 12,
                        child: Text('System 12'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _systemMode[tipIndex] = value;
                        // Wenn zu viele Kreuze für neuen Modus → einkürzen
                        final limit = _maxMarksForTip(tipIndex);
                        if (_selectedPerTip[tipIndex].length > limit) {
                          final sorted =
                              _selectedPerTip[tipIndex].toList()..sort();
                          _selectedPerTip[tipIndex]
                            ..clear()
                            ..addAll(sorted.take(limit));
                        }
                        // Favoriten auf neue Auswahl beschränken
                        _favoritePerTip[tipIndex].removeWhere(
                          (n) => !_selectedPerTip[tipIndex].contains(n),
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Raster 1–49 (7×7)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                  childAspectRatio: 1.0,
                ),
                itemCount: maxNumber,
                itemBuilder: (context, i) {
                  final number = i + 1;
                  final isSelected =
                      _selectedPerTip[tipIndex].contains(number);
                  final isFavorite =
                      _favoritePerTip[tipIndex].contains(number);
                  return _buildNumberCell(
                    tipIndex,
                    number,
                    isSelected,
                    isFavorite,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 2),
          _buildTipFooterNumbers(tipIndex),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

// ========================================================================
// BLOCK 5: ZAHLEN-KUGELN UNTER DEM RASTER (VERBESSERTE VERSION)
// ========================================================================
Widget _buildTipFooterNumbers(int tipIndex) {
  final selected = _selectedPerTip[tipIndex].toList()..sort();
  final fav = _favoritePerTip[tipIndex];

  const double ballSize = 16;
  const double spacing = 3;

  if (selected.isEmpty) {
    return const SizedBox(height: ballSize); // minimale Höhe
  }

  // Anzahl Kugeln → Anzahl Reihen
  final int count = selected.length;
  final int rows = (count / 6).ceil().clamp(1, 2);

  // Footerhöhe = rows × Kugelhöhe + etwas Innenabstand
  final double footerHeight = rows * (ballSize + spacing);

  return SizedBox(
    height: footerHeight,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start, // Kugeln OBEN ausrichten
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final n in selected)
              Container(
                width: ballSize,
                height: ballSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6C0),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fav.contains(n)
                        ? Colors.red.shade900
                        : Colors.blue.shade900,
                    width: fav.contains(n) ? 1.4 : 1.1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: fav.contains(n)
                          ? Colors.red.shade900
                          : Colors.blue.shade900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

  // ========================================================================
  // BLOCK 6: TAP-LOGIK, FAVORITEN & QUICKTIPP
  // ========================================================================
  // ZAHLENFELD + HAND-KREUZ (Favorit rot, sonst blau)
  Widget _buildNumberCell(
    int tipIndex,
    int number,
    bool isSelected,
    bool isFavorite,
  ) {
    final Color selectedNumberColor =
        isFavorite ? Colors.red.shade900 : Colors.blue.shade900;

    return GestureDetector(
      onTap: () => _onNumberTap(tipIndex, number, isSelected),
      onLongPress: () =>
          _onNumberLongPress(tipIndex, number, isSelected, isFavorite),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC00000), width: 0.8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? selectedNumberColor : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              CustomPaint(
                painter: _CrossPainter(
                  isFavorite ? Colors.red.shade900 : Colors.blue.shade900,
                ),
                size: Size.infinite,
              ),
          ],
        ),
      ),
    );
  }

  // Normales An-/Abwählen, Favoriten werden mit entfernt
  void _onNumberTap(int tipIndex, int number, bool alreadySelected) {
    setState(() {
      final set = _selectedPerTip[tipIndex];
      final favSet = _favoritePerTip[tipIndex];

      if (alreadySelected) {
        set.remove(number);
        favSet.remove(number);
        return;
      }

      final int limit = _maxMarksForTip(tipIndex);
      if (set.length >= limit) return;

      set.add(number);
    });
  }

  // LONG-PRESS: Favorit an/aus (überlebt Quicktipp)
  void _onNumberLongPress(
    int tipIndex,
    int number,
    bool alreadySelected,
    bool isFavorite,
  ) {
    setState(() {
      final selSet = _selectedPerTip[tipIndex];
      final favSet = _favoritePerTip[tipIndex];
      final int limit = _maxMarksForTip(tipIndex);

      if (isFavorite) {
        // Favorit wieder zurück in "normal markiert"
        favSet.remove(number);
        return;
      }

      // Favorit setzen → muss ausgewählt sein
      if (!alreadySelected) {
        if (selSet.length >= limit) {
          // wenn voll: versuche, eine Nicht-Favoriten-Zahl zu verdrängen
          final nonFav = selSet.difference(favSet);
          if (nonFav.isEmpty) {
            // alle sind Favoriten → kein Platz
            return;
          }
          selSet.remove(nonFav.first);
        }
        selSet.add(number);
      }

      favSet.add(number);
    });
  }

  // QUICKTIPP-FUNKTION (Favoriten bleiben erhalten)
  void _generateRandomTip(int tipIndex) {
    final fav = _favoritePerTip[tipIndex];
    final limit = _maxMarksForTip(tipIndex);

    // Basis: alle Favoriten
    final newSet = <int>{}..addAll(fav);

    // Wenn Favoriten schon voll machen → nur auf Favoriten begrenzen
    if (newSet.length >= limit) {
      final sorted = newSet.toList()..sort();
      _selectedPerTip[tipIndex]
        ..clear()
        ..addAll(sorted.take(limit));
      return;
    }

    // Rest mit Zufallszahlen auffüllen
    while (newSet.length < limit) {
      newSet.add(_rng.nextInt(maxNumber) + 1);
    }

    _selectedPerTip[tipIndex]
      ..clear()
      ..addAll(newSet);
  }

  void _clearTip(int tipIndex) {
    _selectedPerTip[tipIndex].clear();
    _favoritePerTip[tipIndex].clear();
  }

// ========================================================================
// BLOCK 7: QUICKTIP-LEISTE
// ========================================================================
Widget _buildQuickBar() {
  return Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xFFE0E0E0),
      border: Border(
        top: BorderSide(color: Colors.black54, width: 1),
        bottom: BorderSide(color: Colors.black54, width: 1),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              for (int i = 0; i < tipCount; i++) {
                _generateRandomTip(i);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: const Text('Quicktipp', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            setState(() {
              for (int i = 0; i < tipCount; i++) {
                _clearTip(i);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: const Text('Löschen', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}
  // ========================================================================
  // BLOCK 8: UNTERE FUNKTIONS-LEISTE (LOSNUMMER, ZUSATZ, ZIEHUNG, EINSATZ)
  // ========================================================================
  Widget _buildBottomBar() {
    const redBar = Color(0xFFD00000);

    final double einsatz = _calculateStake();

    return Container(
      color: redBar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Breitenverteilung wie bereits von dir gewünscht angepasst
          Expanded(flex: 9, child: _buildLosnummerBox()),
          const SizedBox(width: 6),
          Expanded(flex: 3, child: _buildZusatzspieleBox()),
          const SizedBox(width: 6),
          Expanded(flex: 3, child: _buildZiehungBox()),
          const SizedBox(width: 6),
          Expanded(flex: 5, child: _buildLaufzeitUndEinsatzBox(einsatz)),
        ],
      ),
    );
  }

  // ========================================================================
  // BLOCK 9: LOSNUMMER-BOX MIT WALZEN (B3) + ORIGINAL-BESCHRIIFTUNG
  // ========================================================================
Widget _buildLosnummerBox() {
  return Container(
    height: 120, // erhöhte Höhe – jetzt passt nichts mehr über
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.black, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // ⭐ Titel ---------------------------------------------------------
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Losnummer',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // ⭐ OBERER BLOCK – Glücksspirale & Super6 -------------------------
        Column(
          children: [
            const Text(
              'GLÜCKSSPIRALE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              height: 1,
              width: 150,
              color: Colors.black,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            const Text(
              'SUPER 6',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              height: 1,
              width: 130,
              color: Colors.black,
              margin: const EdgeInsets.only(bottom: 6),
            ),
          ],
        ),

        // ⭐ WALZEN + ZUFÄLLIG ----------------------------------------------
        LosnummerWalzen(
          targetNumber: _losnummer,
          animationSeed: _losAnimationSeed,
          onRandomPressed: () => setState(_generateNewLosnummer),
        ),

        const SizedBox(height: 4),

        // ⭐ UNTERER BLOCK – Spiel77 / Superzahl ----------------------------
        Column(
          children: [
            Container(
              height: 1,
              width: 150,
              color: Colors.black,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            const Text(
              'Spiel77',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Superzahl',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildZusatzspieleBox() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zusatzspiele',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 2),
          _buildMiniCheckbox(
            'Spiel 77',
            _spiel77,
            (v) => setState(() => _spiel77 = v),
          ),
          const SizedBox(height: 2),
          _buildMiniCheckbox(
            'Super 6',
            _super6,
            (v) => setState(() => _super6 = v),
          ),
          const SizedBox(height: 2),
          _buildMiniCheckbox(
            'GlücksSpirale',
            _gluecksspirale,
            (v) => setState(() => _gluecksspirale = v),
          ),
        ],
      ),
    );
  }

  Widget _buildZiehungBox() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ziehungstage',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildRadioChip('Mi', 0),
              _buildRadioChip('Sa', 1),
              _buildRadioChip('Mi+Sa', 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaufzeitUndEinsatzBox(double einsatz) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laufzeit & Einsatz',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final w in [1, 2, 3, 4, 5])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildLaufzeitChip('$w W', w),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Spieleinsatz: ${einsatz.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // BLOCK 10: EINSATZ-BERECHNUNG + MINI-CHECKBOXEN + CHIPS
  // ========================================================================
  // echte Systempreise
  double _calculateStake() {
    // Grundpreis aus allen nicht-leeren Tipps, unter Berücksichtigung System
    const double preisProReihe = 1.20;
    const double preisSpiel77 = 2.50;
    const double preisSuper6 = 1.25;
    const double preisGluecksspirale = 5.00;
    const double bearbeitungsGebuehr = 0.60;

    double grundpreis = 0.0;

    for (int i = 0; i < tipCount; i++) {
      if (_selectedPerTip[i].isEmpty) continue;
      final rows = _rowsForTip(i);
      grundpreis += rows * preisProReihe;
    }

    if (_spiel77) grundpreis += preisSpiel77;
    if (_super6) grundpreis += preisSuper6;
    if (_gluecksspirale) grundpreis += preisGluecksspirale;

    // Anzahl Ziehungen pro Woche
    final int ziehungenProWoche = _ziehungstage == 2 ? 2 : 1;

    // Gesamteinsatz
    double gesamt =
        grundpreis * ziehungenProWoche * _laufzeitWochen + bearbeitungsGebuehr;
    return gesamt;
  }

  Widget _buildMiniCheckbox(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.black, width: 1),
              color: value ? Colors.red : Colors.white,
            ),
            child: value
                ? const Center(
                    child: Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioChip(String label, int value) {
    final bool selected = _ziehungstage == value;

    return GestureDetector(
      onTap: () {
        setState(() => _ziehungstage = value);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.red,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildLaufzeitChip(String label, int value) {
    final bool selected = _laufzeitWochen == value;

    return GestureDetector(
      onTap: () => setState(() => _laufzeitWochen = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.red,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BLOCK 11: WALZEN-WIDGET FÜR LOSNUMMER (B3: 3D, WIPPEN, BLINKEN)
// ============================================================================
class LosnummerWalzen extends StatefulWidget {
  final String targetNumber;
  final int animationSeed;
  final VoidCallback onRandomPressed;

  const LosnummerWalzen({
    super.key,
    required this.targetNumber,
    required this.animationSeed,
    required this.onRandomPressed,
  });

  @override
  State<LosnummerWalzen> createState() => _LosnummerWalzenState();
}

class _LosnummerWalzenState extends State<LosnummerWalzen> {
  static const _tick = Duration(milliseconds: 40);

  late List<int> _currentDigits;
  late List<bool> _locked;
  Timer? _timer;

  bool _superBlinkVisible = true;

  @override
  void initState() {
    super.initState();
    _initFromTarget();
  }

  void _initFromTarget() {
    _currentDigits = List<int>.filled(7, 0);
    _locked = List<bool>.filled(7, false);

    if (widget.targetNumber.length == 7) {
      for (int i = 0; i < 7; i++) {
        final d = int.tryParse(widget.targetNumber[i]) ?? 0;
        _currentDigits[i] = d;
        _locked[i] = true;
      }
    }
  }

  @override
  void didUpdateWidget(LosnummerWalzen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationSeed != widget.animationSeed ||
        oldWidget.targetNumber != widget.targetNumber) {
      _startSpin();
    }
  }

  void _startSpin() {
    _timer?.cancel();
    _superBlinkVisible = true;
    _locked = List<bool>.filled(7, false);

    final start = DateTime.now();

    _timer = Timer.periodic(_tick, (timer) {
      final elapsedMs = DateTime.now().difference(start).inMilliseconds;
      bool allLocked = true;

      for (int i = 0; i < 7; i++) {
        // Stopzeit je Walze: 0.6s, 0.9s, 1.2s, ..., +0.3s
        final stopTime = 600 + i * 300;

        if (elapsedMs < stopTime) {
          // Drehen – je später, desto sichtbarer langsamer
          _currentDigits[i] = (_currentDigits[i] + 1) % 10;
          allLocked = false;
        } else if (!_locked[i]) {
          // Genau auf Zielziffer stellen
          if (widget.targetNumber.length == 7) {
            final d = int.tryParse(widget.targetNumber[i]) ?? 0;
            _currentDigits[i] = d;
          }
          _locked[i] = true;
        }
      }

      setState(() {});

      if (allLocked) {
        timer.cancel();
        _startWobbleAndBlink();
      }
    });
  }

  void _startWobbleAndBlink() {
    _timer?.cancel();

    if (widget.targetNumber.length != 7) return;
    final target = int.tryParse(widget.targetNumber[6]) ?? 0;

    int phase = 0;
    _superBlinkVisible = true;

    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        // 0–8: 3× Wippbewegung (je 3 Schritte: +1, -1, Ziel)
        if (phase < 9) {
          final m = phase % 3;
          if (m == 0) {
            _currentDigits[6] = (target + 1) % 10;
          } else if (m == 1) {
            _currentDigits[6] = (target + 9) % 10;
          } else {
            _currentDigits[6] = target;
          }
        }
        // 9–14: Blinken Superzahl (3× an/aus)
        else if (phase < 15) {
          _currentDigits[6] = target;
          _superBlinkVisible = !_superBlinkVisible;
        }
        // danach stabil
        else {
          _currentDigits[6] = target;
          _superBlinkVisible = true;
          timer.cancel();
        }

        phase++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Zufällig-Button links
        ElevatedButton(
          onPressed: widget.onRandomPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: const Text(
            'Zufällig',
            style: TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),

        // 7 Walzen
        for (int i = 0; i < 7; i++) _buildWalzenDigit(i),
      ],
    );
  }

  Widget _buildWalzenDigit(int index) {
    final bool isSuper = index == 6;
    final int digit = _currentDigits[index];

    // B3-Optik: leichte 3D-Wölbung über Verlauf + Schatten
    final Gradient gradient = isSuper
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE00000),
              Color(0xFFB00000),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDE0),
              Color(0xFFFFFFFF),
            ],
          );

    final bool visible = !isSuper || _superBlinkVisible;

    return Container(
      width: 22,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 1.5,
            color: Colors.black26,
          ),
        ],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Center(
        child: visible
            ? Text(
                '$digit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSuper ? Colors.white : Colors.black,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ============================================================================
// BLOCK 12: CUSTOM PAINTER – HANDKREUZ (FARBE KONFIGURIERBAR)
// ============================================================================
class _CrossPainter extends CustomPainter {
  final Color color;

  _CrossPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double pad = size.shortestSide * 0.15;

    canvas.drawLine(
      Offset(pad, pad),
      Offset(size.width - pad, size.height - pad),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(pad, size.height - pad),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) =>
      oldDelegate.color != color;
}
