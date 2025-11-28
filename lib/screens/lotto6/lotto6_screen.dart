import 'dart:math';
import 'package:flutter/material.dart';

import 'walzen.dart';

enum TicketMode { normal, system }

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

  /// Ausgewählte Zahlen pro Tippfeld (Kreuze im Gitter)
  late final List<Set<int>> _selectedPerTip;

  /// Generierte Zahlen pro Tipp (finale 6er-Kombi)
  late final List<List<int>> _generatedPerTip;

  /// Aktuelle Highlight-Zahl pro Tipp (für Lauf 1..49)
  late final List<int?> _highlightPerTip;

  /// Ob Tipp gerade animiert wird
  late final List<bool> _tipRunning;

  bool _allRunning = false;

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

  // ---------------------------------------------------------------------------
  // LOSNUMMER & WALZE
  // ---------------------------------------------------------------------------
  void _generateNewLosnummer() {
    _losnummer = List.generate(7, (_) => _rng.nextInt(10)).join();
  }

  Future<void> _openWalzenScreen() async {
    final initialDigits = _losnummer.split('').map(int.parse).toList();
    final result = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute(
        builder: (_) => WalzenScreen(
          initialDigits: initialDigits,
        ),
      ),
    );

    if (result != null && result.length == 7) {
      setState(() {
        _losnummer = result.map((e) => e.toString()).join();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // GENERIERUNG & ANIMATION 1..49
  // ---------------------------------------------------------------------------
  int _maxSelectedForMode() {
    return _mode == TicketMode.normal ? maxNormal : maxSystem;
  }

  Future<void> _generateTip(int tipIndex) async {
    if (_tipRunning[tipIndex] || _allRunning) return;

    _tipRunning[tipIndex] = true;

    final currentSelected = Set<int>.from(_selectedPerTip[tipIndex]);
    final int targetCount = 6;

    // Basis sind die vorhandenen Kreuze
    final Set<int> result = Set<int>.from(currentSelected);

    // Auffüllen bis 6 Zahlen
    while (result.length < targetCount) {
      final n = 1 + _rng.nextInt(maxNumber);
      result.add(n);
    }

    final List<int> sorted = result.toList()..sort();

    setState(() {
      _generatedPerTip[tipIndex] = sorted;
    });

    // Animation 1..49 mit Highlight
    await _runHighlightForTip(tipIndex, sorted);

    _tipRunning[tipIndex] = false;
  }

  Future<void> _runHighlightForTip(int tipIndex, List<int> numbers) async {
    for (int n = 1; n <= maxNumber; n++) {
      if (!mounted) return;

      setState(() {
        _highlightPerTip[tipIndex] = n;
      });

      final bool isHit = numbers.contains(n);
      await Future.delayed(
        Duration(milliseconds: isHit ? 80 : 35),
      );
    }

    if (!mounted) return;

    // Finale Kombination 3x als Lauflicht darstellen
    for (int r = 0; r < 3; r++) {
      for (final n in numbers) {
        if (!mounted) return;
        setState(() {
          _highlightPerTip[tipIndex] = n;
        });
        await Future.delayed(const Duration(milliseconds: 90));
      }
      setState(() {
        _highlightPerTip[tipIndex] = null;
      });
      await Future.delayed(const Duration(milliseconds: 120));
    }

    setState(() {
      _highlightPerTip[tipIndex] = null;
    });
  }

  Future<void> _generateAll() async {
    if (_allRunning) return;

    setState(() {
      _allRunning = true;
    });

    for (int i = 0; i < tipCount; i++) {
      await _generateTip(i);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;

    setState(() {
      _allRunning = false;
    });
  }

  void _clearTip(int index) {
    setState(() {
      _selectedPerTip[index].clear();
      _generatedPerTip[index] = [];
      _highlightPerTip[index] = null;
      _tipRunning[index] = false;
    });
  }

  void _clearAllTips() {
    setState(() {
      for (int i = 0; i < tipCount; i++) {
        _selectedPerTip[i].clear();
        _generatedPerTip[i] = [];
        _highlightPerTip[i] = null;
        _tipRunning[i] = false;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // SELECTION-LOGIK IM GITTER
  // ---------------------------------------------------------------------------
  void _onNumberTap(int tipIndex, int number) {
    final set = _selectedPerTip[tipIndex];
    final maxSel = _maxSelectedForMode();

    setState(() {
      if (set.contains(number)) {
        set.remove(number);
      } else {
        if (set.length >= maxSel) {
          // Beim Normalschein max 6, beim System max 12
          return;
        }
        set.add(number);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // KOMBINATIONEN FÜR SYSTEMANZEIGE
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
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final orientation = media.orientation;
    const background = Color(0xFFFFF6C0); // leicht gelb wie echter Schein

    // im Hochformat 2 Spalten, im Querformat 3
    final int columns =
        orientation == Orientation.portrait ? 2 : 3;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
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
                              aspectRatio: 5 / 4,
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
  // HEADER
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: TicketMode.system,
                    child: Text(
                      'Systemschein',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                onChanged: (mode) {
                  if (mode == null) return;
                  setState(() {
                    _mode = mode;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EINZELNES TIPPFELD
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int tipIndex) {
    final int selectedCount = _selectedPerTip[tipIndex].length;
    final bool isSystem =
        _mode == TicketMode.system && selectedCount > 6;
    final int reihen = _comb(selectedCount, 6);

    const Color normalBorderColor = Color(0xFFC00000);
    final Color borderColor =
        isSystem ? Colors.red.shade900 : normalBorderColor;
    final Color fillColor =
        isSystem ? const Color(0xFFFFE0E0) : Colors.white;

    final List<int> generated = _generatedPerTip[tipIndex];

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Titel + System-/Anzahlinfo
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
                else if (_mode == TicketMode.normal &&
                    selectedCount > 0)
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

          // Gitter 1..49
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              child: _buildNumberGrid(tipIndex),
            ),
          ),

          // Finale 6 Zahlen als Kugeln
          SizedBox(
            height: 28,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 3,
                  children: List.generate(6, (i) {
                    final int? val =
                        (i < generated.length) ? generated[i] : null;
                    return _buildBall(val);
                  }),
                ),
              ),
            ),
          ),

          // Buttons: Tipp generieren + Löschen
          SizedBox(
            height: 26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed:
                      _tipRunning[tipIndex] ? null : () => _generateTip(tipIndex),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(
                    _tipRunning[tipIndex] ? 'Läuft…' : 'Generieren',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _clearTip(tipIndex),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GITTER 1..49
  // ---------------------------------------------------------------------------
  Widget _buildNumberGrid(int tipIndex) {
    const Color gridBorderColor = Color(0xFFC00000);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: maxNumber,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, i) {
        final int number = i + 1;
        final bool selected =
            _selectedPerTip[tipIndex].contains(number);
        final bool isHighlight =
            _highlightPerTip[tipIndex] == number;

        Color textColor = Colors.black;
        Color bgColor = Colors.white;

        if (selected) {
          textColor = Colors.blue.shade900;
        }
        if (isHighlight) {
          bgColor = const Color(0xFFFFE4B5);
        }

        return GestureDetector(
          onTap: () => _onNumberTap(tipIndex, number),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: gridBorderColor, width: 0.8),
            ),
            child: Center(
              child: Text(
                selected ? 'X' : '$number',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
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
  // KLEINE KUGELN FÜR FINALE ZAHLEN
  // ---------------------------------------------------------------------------
  Widget _buildBall(int? n) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red,
          width: 1.3,
        ),
      ),
      child: n == null
          ? const SizedBox.shrink()
          : Center(
              child: Text(
                '$n',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // UNTERE ROTE LEISTE
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar() {
    const Color redBar = Color(0xFFD00000);

    return Container(
      height: 110,
      color: redBar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // WALZE + LOSNUMMER
          Expanded(
            flex: 4,
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
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: _generateNewLosnummer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Zufällig',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: _openWalzenScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Walze',
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

          // ZUSATZSPIELE
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
                        (v) =>
                            setState(() => _gluecksspirale = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ZIEHUNGSTAGE + LAUFZEIT
          Expanded(
            flex: 4,
            child: Column(
              children: [
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
  // ZIEHUNGSTAGE-CHIP
  // ---------------------------------------------------------------------------
  Widget _buildRadioChip(String label, int value) {
    final bool selected = _ziehungstage == value;

    return GestureDetector(
      onTap: () {
        setState(() => _ziehungstage = value);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
  // LAUFZEIT-CHIP
  // ---------------------------------------------------------------------------
  Widget _buildLaufzeitChip(String label, int value) {
    final bool selected = _laufzeitWochen == value;

    return GestureDetector(
      onTap: () => setState(() => _laufzeitWochen = value),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
