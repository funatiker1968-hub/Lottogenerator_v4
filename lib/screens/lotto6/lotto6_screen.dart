import 'dart:math';
import 'package:flutter/material.dart';

import 'losnummer_walzen_dialog.dart';
import 'widgets/losnummer_legend.dart';

/// Modus: Normalschein (max 6 Kreuze) oder Systemschein (mehr Kreuze)
enum TicketMode { normal, system }

/// Lotto 6aus49 Screen im Stil eines Papier-Lottoscheins
class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  // ---------------------------------------------------------------------------
  // KONSTANTEN
  // ---------------------------------------------------------------------------
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int maxNormal = 6;
  static const int maxSystem = 12;

  final Random _rng = Random();

  TicketMode _mode = TicketMode.normal;

  /// ausgewählte Zahlen (Kreuze) pro Tippfeld
  late final List<Set<int>> _selectedPerTip;

  /// aktuell generierte 6 Zahlen pro Tippfeld (für die Kugelreihe unten)
  late final List<List<int>> _generatedPerTip;

  /// aktuell hervorgehobene Zahl (1..49) pro Tippfeld während der Durchlaufanimation
  late final List<int?> _highlightPerTip;

  /// läuft gerade eine Generierung für dieses Tippfeld?
  late final List<bool> _tipRunning;

  /// Zusatzspiele
  bool _spiel77 = false;
  bool _super6 = false;
  bool _gluecksspirale = false;

  /// Ziehungstage: 0 = Mi, 1 = Sa, 2 = Mi+Sa
  int _ziehungstage = 0;

  /// Laufzeit in Wochen: 1,2,4 oder 0 = Dauerschein
  int _laufzeitWochen = 1;

  /// 7-stellige Losnummer
  late String _losnummer;

  @override
  void initState() {
    super.initState();
    _selectedPerTip = List.generate(tipCount, (_) => <int>{});
    _generatedPerTip = List.generate(tipCount, (_) => <int>[]);
    _highlightPerTip = List<int?>.filled(tipCount, null);
    _tipRunning = List<bool>.filled(tipCount, false);
    _generateNewLosnummer();
  }

  void _generateNewLosnummer() {
    _losnummer = List.generate(7, (_) => _rng.nextInt(10)).join();
  }

  int _maxForCurrentMode() =>
      _mode == TicketMode.normal ? maxNormal : maxSystem;

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF6C0); // leicht gelb wie Papier-Schein

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
                    final orientation = MediaQuery.of(ctx).orientation;
                    final int columns =
                        orientation == Orientation.portrait ? 2 : 3;
                    const spacing = 8.0;
                    final totalWidth = constraints.maxWidth;
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
                              aspectRatio: 5 / 4, // nah am Papierlayout
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
  // KOPF: Titel + Normalschein/Systemschein
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
  // EIN TIPP-FELD
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int tipIndex) {
    final int selectedCount = _selectedPerTip[tipIndex].length;
    final bool isSystem = _mode == TicketMode.system && selectedCount > 6;
    final int reihen =
        isSystem ? _comb(selectedCount, maxNormal) : 0; // Systemreihen

    const Color normalBorderColor = Color(0xFFC00000);
    final Color borderColor =
        isSystem ? Colors.red.shade900 : normalBorderColor;
    final Color fillColor =
        isSystem ? const Color(0xFFFFE0E0) : Colors.white;

    final List<int> balls = _generatedPerTip[tipIndex];

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Kopfzeile "Tipp X" + Info
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
                    '$selectedCount / $maxNormal',
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

          // Raster 1–49
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: _buildNumberGrid(tipIndex),
            ),
          ),

          // Kugelreihe + Generieren/Löschen
          SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  // 6 Kugeln
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 4,
                        children: List.generate(6, (i) {
                          final int? n =
                              i < balls.length ? balls[i] : null;
                          return _buildBall(n);
                        }),
                      ),
                    ),
                  ),
                  // Generieren
                  TextButton(
                    onPressed: () => _generateTip(tipIndex),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Generieren',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Löschen
                  TextButton(
                    onPressed: () => _clearTip(tipIndex),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GRID 1..49 (7×7)
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
        final int number = i + 1;
        final bool selected = _selectedPerTip[tipIndex].contains(number);
        final bool isHighlight = _highlightPerTip[tipIndex] == number;

        Color bg = Colors.white;
        if (isHighlight) {
          bg = const Color(0xFFFFF2CC); // leicht gelb beim Durchlauf
        }

        return GestureDetector(
          onTap: () => _onNumberTap(tipIndex, number, selected),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: gridBorderColor, width: 0.8),
            ),
            child: Center(
              child: Text(
                selected ? 'X' : '$number',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.blue.shade900 : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAP AUF ZAHL
  // ---------------------------------------------------------------------------
  void _onNumberTap(int tipIndex, int number, bool alreadySelected) {
    setState(() {
      final set = _selectedPerTip[tipIndex];

      if (alreadySelected) {
        set.remove(number);
        return;
      }

      final int limit = _maxForCurrentMode();
      if (set.length >= limit) {
        // im Normalschein max 6, im Systemschein max 12
        return;
      }
      set.add(number);
    });
  }

  // ---------------------------------------------------------------------------
  // EINZELTIPP GENERIEREN + ANIMATION
  // ---------------------------------------------------------------------------
  Future<void> _generateTip(int tipIndex) async {
    if (_tipRunning[tipIndex]) return;
    _tipRunning[tipIndex] = true;

    final set = _selectedPerTip[tipIndex];
    final int limit = _maxForCurrentMode();

    // fehlende Zahlen zufällig auffüllen
    while (set.length < limit) {
      final int n = 1 + _rng.nextInt(maxNumber);
      set.add(n);
    }

    final List<int> sorted = set.toList()..sort();
    // für die 6 Kugeln unten: immer genau 6 anzeigen (erste 6 der sortierten)
    final List<int> six = sorted.length <= maxNormal
        ? List<int>.from(sorted)
        : sorted.take(maxNormal).toList();

    setState(() {
      _generatedPerTip[tipIndex] = six;
    });

    // Durchlauf 1..49 mit Highlight
    await _runHighlightForTip(tipIndex, six);

    _tipRunning[tipIndex] = false;
  }

  Future<void> _runHighlightForTip(int tipIndex, List<int> hits) async {
    const int normalDelayMs = 40;
    const int hitExtraDelayMs = 90;

    for (int n = 1; n <= maxNumber; n++) {
      if (!mounted) return;

      setState(() => _highlightPerTip[tipIndex] = n);

      final bool isHit = hits.contains(n);
      final int delay = isHit ? normalDelayMs + hitExtraDelayMs : normalDelayMs;
      await Future.delayed(Duration(milliseconds: delay));
    }

    if (!mounted) return;
    setState(() => _highlightPerTip[tipIndex] = null);

    // finale Blinksequenz der 6 Zahlen
    await _finalBlink(tipIndex, hits);
  }

  Future<void> _finalBlink(int tipIndex, List<int> hits) async {
    if (hits.isEmpty) return;

    for (int r = 0; r < 3; r++) {
      for (final n in hits) {
        if (!mounted) return;
        setState(() => _highlightPerTip[tipIndex] = n);
        await Future.delayed(const Duration(milliseconds: 80));
      }
      if (!mounted) return;
      setState(() => _highlightPerTip[tipIndex] = null);
      await Future.delayed(const Duration(milliseconds: 80));
    }
    if (!mounted) return;
    setState(() => _highlightPerTip[tipIndex] = null);
  }

  // ---------------------------------------------------------------------------
  // KOMBI-FUNKTION n über k (für System-Reihenanzeige)
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
  // TIPP LEEREN / ALLE LEEREN
  // ---------------------------------------------------------------------------
  void _clearTip(int tipIndex) {
    setState(() {
      _selectedPerTip[tipIndex].clear();
      _generatedPerTip[tipIndex] = [];
      _highlightPerTip[tipIndex] = null;
      _tipRunning[tipIndex] = false;
    });
  }

  Future<void> _generateAll() async {
    for (int i = 0; i < tipCount; i++) {
      await _generateTip(i);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _clearAllTips() {
    for (int i = 0; i < tipCount; i++) {
      _clearTip(i);
    }
  }

  // ---------------------------------------------------------------------------
  // KUGEL FÜR FINALE ZAHLEN
  // ---------------------------------------------------------------------------
  Widget _buildBall(int? n) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC00000), width: 1),
      ),
      child: n == null
          ? const SizedBox.shrink()
          : Center(
              child: Text(
                '$n',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // UNTERE LEISTE: Losnummer, Zusatzspiele, Ziehungstage, Laufzeit
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar() {
    const redBar = Color(0xFFD00000);

    return Container(
      height: 110,
      color: redBar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Losnummer + Buttons + Legende
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
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
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
                      const SizedBox(width: 6),
                      // Zufällig-Button (direkt)
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
                      const SizedBox(width: 6),
                      // Walzen-Button (Dialog)
                      ElevatedButton(
                        onPressed: () async {
                          await showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => LosnummerWalzenDialog(
                              initialLosnummer: _losnummer,
                              totalDuration:
                                  const Duration(milliseconds: 3500),
                              onDone: (value) {
                                setState(() {
                                  _losnummer = value;
                                });
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                        ),
                        child: const Text(
                          'Walze',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const LosnummerLegend(
                    fontSize: 8,
                    bracketHeight: 8,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Zusatzspiele
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

          // Ziehungstage + Laufzeit
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Ziehungstage
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
                // Laufzeit
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
                        Row(
                          children: [
                            _buildLaufzeitChip('1 Woche', 1),
                            _buildLaufzeitChip('2 Wochen', 2),
                            _buildLaufzeitChip('4 Wochen', 4),
                            _buildLaufzeitChip('Dauer', 0),
                          ],
                        ),
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
  // MINI-CHECKBOXEN
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
  // ZIEHUNGSTAG CHIP
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
  // LAUFZEIT CHIP
  // ---------------------------------------------------------------------------
  Widget _buildLaufzeitChip(String label, int value) {
    final bool selected = _laufzeitWochen == value;

    return GestureDetector(
      onTap: () => setState(() => _laufzeitWochen = value),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
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
