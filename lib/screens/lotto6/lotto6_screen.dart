import 'dart:math';
import 'package:flutter/material.dart';

enum TicketMode { normal, system }

/// Lotto 6aus49 im Stil des Papier-Lottoscheins
/// - 12 Tippfelder à 1–49
/// - Normalschein/Systemschein
/// - Favoriten (manuell) + Generierung (füllt auf)
/// - Durchlauf-Animation 1..49 mit Highlight bei Treffern
/// - Losnummer + Zusatzspiele + Ziehungstage + Laufzeit
class Lotto6Screen extends StatefulWidget {
  const Lotto6Screen({super.key});

  @override
  State<Lotto6Screen> createState() => _Lotto6ScreenState();
}

class _Lotto6ScreenState extends State<Lotto6Screen> {
  static const int tipCount = 12;
  static const int maxNumber = 49;
  static const int maxNormal = 6;
  static const int maxSystem = 12;

  final Random _rng = Random();

  TicketMode _mode = TicketMode.normal;

  /// Manuelle Kreuze = Favoriten (werden nicht überschrieben)
  late final List<Set<int>> _favoritesPerTip;

  /// Generierte Zahlen (nur die, die der Generator hinzufügt)
  late final List<Set<int>> _generatedPerTip;

  /// Aktuell gehighlightete Zahl bei der 1..49-Durchlaufanimation
  late final List<int?> _highlightPerTip;

  /// Läuft gerade für dieses Tippfeld eine Animation?
  late final List<bool> _tipRunning;

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
    _favoritesPerTip = List.generate(tipCount, (_) => <int>{});
    _generatedPerTip = List.generate(tipCount, (_) => <int>{});
    _highlightPerTip = List<int?>.filled(tipCount, null);
    _tipRunning = List<bool>.filled(tipCount, false);
    _generateNewLosnummer();
  }

  void _generateNewLosnummer() {
    _losnummer = List.generate(7, (_) => _rng.nextInt(10)).join();
  }

  int _maxForCurrentMode() =>
      _mode == TicketMode.normal ? maxNormal : maxSystem;

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
                              aspectRatio: 5 / 4, // ähnliches Format wie Schein
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
    final int selectedCount = _favoritesPerTip[tipIndex].length;
    final bool isSystem = _mode == TicketMode.system && selectedCount > 6;
    final int reihen = _comb(selectedCount, 6);

    const Color normalBorderColor = Color(0xFFC00000);

    final Color borderColor =
        isSystem ? Colors.red.shade900 : normalBorderColor;

    final Color fillColor =
        isSystem ? const Color(0xFFFFE0E0) : Colors.white;

    final bool canGenerate =
        !_tipRunning[tipIndex] && selectedCount < _maxForCurrentMode();

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

          // Button-Leiste: Generieren + Löschen
          SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: canGenerate
                          ? () => _generateTip(tipIndex)
                          : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        _tipRunning[tipIndex] ? 'Läuft…' : 'Generieren',
                        style: TextStyle(
                          fontSize: 9,
                          color: canGenerate
                              ? Colors.green.shade900
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _favoritesPerTip[tipIndex].clear();
                          _generatedPerTip[tipIndex].clear();
                          _highlightPerTip[tipIndex] = null;
                          _tipRunning[tipIndex] = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
// ---------------------------------------------------------------------------
  // RASTER 1..49 (FAVORITEN + GENERIERTE + HIGHLIGHT)
  // ---------------------------------------------------------------------------
  Widget _buildNumberGrid(int tipIndex) {
    const Color gridBorderColor = Color(0xFFC00000);

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

        final bool fav = _favoritesPerTip[tipIndex].contains(number);
        final bool gen = _generatedPerTip[tipIndex].contains(number);
        final bool hi = _highlightPerTip[tipIndex] == number;

        // Darstellung
        final Color bg = hi
            ? const Color(0xFFFFE8A0)
            : Colors.white;

        final Color border = fav
            ? Colors.red
            : gen
                ? Colors.black
                : gridBorderColor;

        final Color textColor =
            fav ? Colors.red.shade900 : Colors.black;

        final String label = gen ? 'X' : '$number';

        return GestureDetector(
          onTap: () => _onNumberTap(tipIndex, number, fav),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 0.8),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      gen ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAP-LOGIK (Favoriten, max 6 im Normalmodus)
  // ---------------------------------------------------------------------------
  void _onNumberTap(int tipIndex, int number, bool alreadyFav) {
    final maxSel = _maxForCurrentMode();
    final set = _favoritesPerTip[tipIndex];

    setState(() {
      if (alreadyFav) {
        // abwählen
        set.remove(number);
        return;
      }

      // neu anwählen
      if (set.length >= maxSel) {
        // im Normalmodus max 6
        // im System max 12
        return;
      }

      set.add(number);
    });
  }

  // ---------------------------------------------------------------------------
  // TIPP GENERIEREN (füllt nur fehlende Zahlen auf, Favoriten bleiben)
  // ---------------------------------------------------------------------------
  Future<void> _generateTip(int tipIndex) async {
    if (_tipRunning[tipIndex]) return;

    setState(() => _tipRunning[tipIndex] = true);

    final favs = _favoritesPerTip[tipIndex];
    final gens = _generatedPerTip[tipIndex];

    final int maxSel = _maxForCurrentMode();

    // Generator soll nur Auffüllen bis 6 (oder 12 bei System)
    while (favs.length + gens.length < maxSel) {
      final n = 1 + _rng.nextInt(maxNumber);
      if (favs.contains(n)) continue;
      gens.add(n);
    }

    // Reihenfolge sortieren
    final sorted = [...favs, ...gens]..sort();

    // Speichern
    setState(() {
      _generatedPerTip[tipIndex] = sorted.toSet();
    });

    // Animation starten
    await _runHighlightForTip(tipIndex);

    if (mounted) {
      setState(() => _tipRunning[tipIndex] = false);
    }
  }

  // ---------------------------------------------------------------------------
  // DURCHLAUF 1..49 – Treffer blinken länger
  // ---------------------------------------------------------------------------
  Future<void> _runHighlightForTip(int tipIndex) async {
    final hits = _generatedPerTip[tipIndex];
    if (hits.isEmpty) return;

    for (int n = 1; n <= maxNumber; n++) {
      if (!mounted) return;

      setState(() => _highlightPerTip[tipIndex] = n);

      if (hits.contains(n)) {
        await Future.delayed(const Duration(milliseconds: 120));
      } else {
        await Future.delayed(const Duration(milliseconds: 40));
      }
    }

    if (!mounted) return;
    setState(() => _highlightPerTip[tipIndex] = null);

    await _finalBlink(tipIndex);
  }

  // ---------------------------------------------------------------------------
  // FINALE BLINKSEQUENZ DER 6 ZAHLEN
  // ---------------------------------------------------------------------------
  Future<void> _finalBlink(int tipIndex) async {
    final hits = _generatedPerTip[tipIndex];
    final sorted = hits.toList()..sort();

    for (int r = 0; r < 3; r++) {
      for (final n in sorted) {
        if (!mounted) return;
        setState(() => _highlightPerTip[tipIndex] = n);
        await Future.delayed(const Duration(milliseconds: 80));
      }
      setState(() => _highlightPerTip[tipIndex] = null);
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  // ---------------------------------------------------------------------------
  // KOMBINATIONEN (Systemschein)
  // ---------------------------------------------------------------------------
  int _comb(int n, int k) {
    if (n < k) return 0;
    int r = 1;
    for (int i = 1; i <= k; i++) {
      r = r * (n - k + i) ~/ i;
    }
    return r;
  }
// ---------------------------------------------------------------------------
  // UNTERE ROTE LEISTE (Losnummer + Zusatzspiele + Ziehungstage + Laufzeit)
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      height: 100,
      color: const Color(0xFFD00000),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // -----------------------------------------------------------------
          // LOSNUMMER
          // -----------------------------------------------------------------
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
                          width: 20,
                          height: 26,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1),
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
                      ElevatedButton(
                        onPressed: () {
                          setState(_generateNewLosnummer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        child:
                            const Text('Zufällig', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // -----------------------------------------------------------------
          // ZUSATZSPIELE: Spiel77, Super6, Glücksspirale
          // -----------------------------------------------------------------
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
                      _buildMiniCheckbox('Spiel 77', _spiel77,
                          (v) => setState(() => _spiel77 = v)),
                      _buildMiniCheckbox('SUPER 6', _super6,
                          (v) => setState(() => _super6 = v)),
                      _buildMiniCheckbox('Glücksspirale', _gluecksspirale,
                          (v) => setState(() => _gluecksspirale = v)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // -----------------------------------------------------------------
          // ZIEHUNGSTAGE + LAUFZEIT
          // -----------------------------------------------------------------
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
  Widget _buildMiniCheckbox(String label, bool value, Function(bool) onChanged) {
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
                    child: Icon(Icons.check, size: 10, color: Colors.white),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ZIEHUNGS-TAG CHIP
  // ---------------------------------------------------------------------------
  Widget _buildRadioChip(String label, int value) {
    final bool selected = _ziehungstage == value;

    return GestureDetector(
      onTap: () => setState(() => _ziehungstage = value),
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
