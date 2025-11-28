import 'dart:math';
import 'package:flutter/material.dart';

enum TicketMode { normal, system }

/// Lotto 6aus49 im Stil des Papier-Lottoscheins.
/// 12 Tippfelder (1–49), Normalschein/Systemschein,
/// Losnummer + Zusatzspiele + Ziehungstage + Laufzeit.
class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;

  final Random _rng = Random();

  TicketMode _mode = TicketMode.normal;

  /// ausgewählte Zahlen pro Tippfeld
  late final List<Set<int>> _selectedPerTip;

  /// Zusatzspiele
  bool _spiel77 = false;
  bool _super6 = false;
  bool _gluecksspirale = false;

  /// Ziehungstage: 0 = Mi, 1 = Sa, 2 = Mi+Sa
  int _ziehungstage = 0;

  /// Laufzeit (1,2,4 Wochen oder 0 = Dauer)
  int _laufzeitWochen = 1;

  /// 7-stellige Losnummer
  late String _losnummer;

  @override
  void initState() {
    super.initState();
    _selectedPerTip = List.generate(tipCount, (_) => <int>{});
    _generateNewLosnummer();
  }

  void _generateNewLosnummer() {
    _losnummer = List.generate(7, (_) => _rng.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final orientation = media.orientation;
    const background = Color(0xFFFFF6C0); // leicht gelb wie echter Schein

    final int columns = orientation == Orientation.portrait ? 2 : 3;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),

            // Tippfelder (12)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final totalWidth = constraints.maxWidth;
                    const spacing = 8.0;
                    final cardWidth =
                        (totalWidth - (columns - 1) * spacing) / columns;

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: List.generate(tipCount, (index) {
                          return SizedBox(
                            width: cardWidth,
                            child: AspectRatio(
                              aspectRatio: 5 / 4, // ungefähr echtes Format
                              child: _buildTipCard(index),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEAD-BEREICH – Lotto 6aus49 Titel + Modus-Umschalter
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      height: 56,
      color: const Color(0xFFFFD000),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'LOTTO 6aus49',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          const Spacer(),

          // Umschalter Normal <-> System
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TicketMode>(
                value: _mode,
                dropdownColor: Colors.red.shade700,
                iconEnabledColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: TicketMode.normal,
                    child: Text(
                      'Normalschein',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  DropdownMenuItem(
                    value: TicketMode.system,
                    child: Text(
                      'Systemschein',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
                onChanged: (mode) {
                  if (mode == null) return;
                  setState(() => _mode = mode);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EINZELNE TIPP-KARTE
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int tipIndex) {
    final int selectedCount = _selectedPerTip[tipIndex].length;

    final bool isSystem = _mode == TicketMode.system && selectedCount > 6;

    final int reihen = _comb(selectedCount, 6);

    const Color normalBorderColor = Color(0xFFC00000);

    final Color borderColor =
        isSystem ? Colors.red.shade900 : normalBorderColor;

    final Color fillColor =
        isSystem ? const Color(0xFFFFE0E0) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Kopfzeile: Tipp X + Anzeige Normal/System
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  'Tipp ${tipIndex + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),

                if (_mode == TicketMode.system && selectedCount >= 6)
                  Text(
                    'System ${selectedCount.toString().padLeft(2, '0')}  (${reihen} R.)',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  )
                else if (_mode == TicketMode.normal && selectedCount > 0)
                  Text(
                    '$selectedCount / 6',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),

          // Raster 1..49
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: _buildNumberGrid(tipIndex),
            ),
          ),

          // Löschen-Button
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() => _selectedPerTip[tipIndex].clear());
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'Löschen',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
// ---------------------------------------------------------------------------
  // Raster 1..49 (7×7) wie auf dem Papier-Lottoschein
  // ---------------------------------------------------------------------------
  Widget _buildNumberGrid(int tipIndex) {
    const gridBorderColor = Color(0xFFC00000);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: maxNumber,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, i) {
        final number = i + 1;
        final selected = _selectedPerTip[tipIndex].contains(number);

        return GestureDetector(
          onTap: () => _onNumberTap(tipIndex, number, selected),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: gridBorderColor, width: 0.8),
            ),
            child: Center(
              child: Text(
                selected ? 'X' : '$number',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color:
                      selected ? Colors.blue.shade900 : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Logik: Zahl anklicken
  // ---------------------------------------------------------------------------
  void _onNumberTap(int tipIndex, int number, bool alreadySelected) {
    setState(() {
      final set = _selectedPerTip[tipIndex];

      if (alreadySelected) {
        set.remove(number);
        return;
      }

      if (_mode == TicketMode.normal) {
        if (set.length >= 6) {
          // Normalschein: max. 6 Kreuze
          return;
        }
        set.add(number);
      } else {
        // Systemschein: max. 12 Zahlen
        if (set.length >= 12) return;
        set.add(number);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Kombinationsfunktion n über k (Anzahl Reihen im Systemschein)
  // ---------------------------------------------------------------------------
  int _comb(int n, int k) {
    if (n < k) return 0;
    if (k == 0 || n == k) return 1;
    int r = 1;
    for (int i = 1; i <= k; i++) {
      r = r * (n - k + i) ~/ i;
    }
    return r;
  }

  // ---------------------------------------------------------------------------
  // Untere rote Leiste (Losnummer + Zusatzspiele + Ziehungstage + Laufzeit)
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar() {
    const redBar = Color(0xFFD00000);

    return Container(
      height: 90,
      color: redBar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // ----------------------------------------------------------
          // LOSNUMMER
          // ----------------------------------------------------------
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Losnummer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (int i = 0; i < _losnummer.length; i++)
                        Container(
                          width: 18,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _losnummer[i],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(_generateNewLosnummer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                        child: const Text(
                          'Zufällig',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),
// ----------------------------------------------------------
          // ZUSATZSPIELE
          // ----------------------------------------------------------
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      _buildMiniCheckbox(
                        'Spiel 77',
                        _spiel77,
                        (v) => setState(() => _spiel77 = v),
                      ),
                      _buildMiniCheckbox(
                        'SUPER 6',
                        _super6,
                        (v) => setState(() => _super6 = v),
                      ),
                      _buildMiniCheckbox(
                        'Glücksspirale',
                        _gluecksspirale,
                        (v) => setState(() => _gluecksspirale = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ----------------------------------------------------------
          // ZIEHUNGSTAGE + LAUFZEIT
          // ----------------------------------------------------------
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // -------- Ziehungstage ----------
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _buildRadioChip('Mi', 0),
                            _buildRadioChip('Sa', 1),
                            _buildRadioChip('Mi+Sa', 2),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // -------- Laufzeit ----------
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Laufzeit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildLaufzeitRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mini-Checkboxen (Zusatzspiele)
  // ---------------------------------------------------------------------------
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
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Radiobutton Chips (Ziehungstage)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Laufzeit-Row Chips
  // ---------------------------------------------------------------------------
  Widget _buildLaufzeitRow() {
    Widget chip(String label, int value) {
      final bool selected = _laufzeitWochen == value;

      return GestureDetector(
        onTap: () {
          setState(() => _laufzeitWochen = value);
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

    return Row(
      children: [
        chip('1 Woche', 1),
        chip('2 Wochen', 2),
        chip('4 Wochen', 4),
        chip('Dauer', 0),
      ],
    );
  }
}
