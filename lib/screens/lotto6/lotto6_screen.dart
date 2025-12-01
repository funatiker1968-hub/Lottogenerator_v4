import 'dart:math';
import 'package:flutter/material.dart';

import 'losnummer_walzen_dialog.dart';

/// Modus wie auf dem Original: Normalschein / Systemschein
enum TicketMode { normal, system }

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
  static const double einsatzProReihe = 1.20; // EUR

  final Random _rng = Random();

  TicketMode _mode = TicketMode.normal;

  /// Ausgewählte Zahlen pro Tippfeld
  late final List<Set<int>> _selectedPerTip;

  /// 7-stellige Losnummer
  late String _losnummer;

  bool _gluecksspirale = false;
  bool _super6 = false;
  bool _spiel77 = false;

  /// Einfache Spielschein-Speicherung im Speicher (max 10)
  final List<List<Set<int>>> _savedSheets = <List<Set<int>>>[];

  @override
  void initState() {
    super.initState();
    _selectedPerTip = List.generate(tipCount, (_) => <int>{});
    _generateNewLosnummer();
  }

  void _generateNewLosnummer() {
    _losnummer = List.generate(7, (_) => _rng.nextInt(10)).join();
  }

  int _maxForMode() =>
      _mode == TicketMode.normal ? maxNormal : maxSystem;

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6C0), // Papiergelb
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            Expanded(child: _buildTipsGrid()),
            _buildQuickArea(),
            _buildLosnummerBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER (Titel + Normalschein/Systemschein)
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
              fontSize: 22,
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
                onChanged: (m) {
                  if (m == null) return;
                  setState(() {
                    _mode = m;
                    // Bei Moduswechsel ggf. zu viele Zahlen abschneiden
                    for (final set in _selectedPerTip) {
                      while (set.length > _maxForMode()) {
                        set.remove(set.last);
                      }
                    }
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
  // TIPPFELDER-GRID (12 Felder, 2×3 oder 3×4)
  // ---------------------------------------------------------------------------
  Widget _buildTipsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.of(context).orientation;
        final int columns = orientation == Orientation.portrait ? 2 : 3;

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
                  aspectRatio: 4 / 5,
                  child: _buildTipCard(index),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // EIN TIPP-FELD
  // ---------------------------------------------------------------------------
  Widget _buildTipCard(int tipIndex) {
    final set = _selectedPerTip[tipIndex];
    final einsatz = _berechneEinsatz(set);

    const Color borderColor = Color(0xFFC00000);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Kopfzeile: Tipp X + Einsatz
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
                Text(
                  einsatz > 0
                      ? 'Einsatz: ${einsatz.toStringAsFixed(2)} €'
                      : 'Einsatz: –',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Raster 1–49
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: _buildNumberGrid(tipIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberGrid(int tipIndex) {
    final set = _selectedPerTip[tipIndex];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7×7 wie auf dem Original
      ),
      itemCount: maxNumber,
      itemBuilder: (context, i) {
        final number = i + 1;
        final selected = set.contains(number);

        return GestureDetector(
          onTap: () => _onNumberTap(tipIndex, number, selected),
          child: Container(
            margin: const EdgeInsets.all(0.2),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFC00000),
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                if (selected)
                  Text(
                    'X',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onNumberTap(int tipIndex, int number, bool alreadySelected) {
    setState(() {
      final set = _selectedPerTip[tipIndex];
      if (alreadySelected) {
        set.remove(number);
        return;
      }
      final limit = _maxForMode();
      if (set.length >= limit) return;
      set.add(number);
    });
  }

  double _berechneEinsatz(Set<int> set) {
    if (set.length < maxNormal) return 0.0;
    if (_mode == TicketMode.normal) {
      // Eine Reihe pro Tipp
      return einsatzProReihe;
    }
    final int n = set.length;
    final int reihen = _comb(n, maxNormal);
    return reihen * einsatzProReihe;
  }

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
  // QUICKTIPP-BEREICH (2 graue Zeilen wie auf dem Original)
  // ---------------------------------------------------------------------------
  Widget _buildQuickArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QuickTipp Felder
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFE0E0E0),
            border: Border(
              top: BorderSide(color: Colors.black54, width: 1),
              bottom: BorderSide(color: Colors.black26, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'QuickTipp Felder',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              for (final count in [1, 2, 3, 4, 6])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _smallGreyButton(
                    label: '+$count',
                    onPressed: () => _quickFill(count),
                  ),
                ),
            ],
          ),
        ),

        // Spielschein (Neu / Laden / Speichern)
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFE0E0E0),
            border: Border(
              top: BorderSide(color: Colors.black26, width: 1),
              bottom: BorderSide(color: Colors.black54, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Spielschein',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              _smallGreyButton(label: 'Neu', onPressed: _clearAllTips),
              const SizedBox(width: 4),
              _smallGreyButton(label: 'Laden', onPressed: _loadLastSheet),
              const SizedBox(width: 4),
              _smallGreyButton(label: 'Speichern', onPressed: _saveCurrentSheet),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallGreyButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 26,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEEEEEE),
          foregroundColor: Colors.black,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: const BorderSide(color: Colors.black54, width: 1),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _quickFill(int count) {
    setState(() {
      int filled = 0;
      for (int i = 0; i < tipCount && filled < count; i++) {
        final set = _selectedPerTip[i];
        if (set.isNotEmpty) continue;
        while (set.length < maxNormal) {
          final n = 1 + _rng.nextInt(maxNumber);
          set.add(n);
        }
        filled++;
      }
    });
  }

  void _clearAllTips() {
    setState(() {
      for (final set in _selectedPerTip) {
        set.clear();
      }
    });
  }

  void _saveCurrentSheet() {
    final copy = _selectedPerTip
        .map((s) => Set<int>.from(s))
        .toList(growable: false);
    setState(() {
      _savedSheets.add(copy);
      if (_savedSheets.length > 10) {
        _savedSheets.removeAt(0);
      }
    });
  }

  void _loadLastSheet() {
    if (_savedSheets.isEmpty) return;
    final last = _savedSheets.last;
    setState(() {
      for (int i = 0; i < tipCount; i++) {
        _selectedPerTip[i]
          ..clear()
          ..addAll(last[i]);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // LOSNUMMER-LEISTE (rote Unterkante)
  // ---------------------------------------------------------------------------
  Widget _buildLosnummerBar() {
    const redBar = Color(0xFFD00000);

    return Container(
      color: redBar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOSNUMMER Überschrift
          const Text(
            'LO S N U M M E R',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),

          // Ziffern + Buttons
          Row(
            children: [
              // Zufällig
              ElevatedButton(
                onPressed: () {
                  setState(_generateNewLosnummer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: const Text(
                  'Zufällig',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),

              // Losnummer-Kästchen
              for (int i = 0; i < _losnummer.length; i++)
                Container(
                  width: 24,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.4),
                    color: i == 6
                        ? Colors.red.shade700
                        : Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      _losnummer[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: i == 6 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              // Walze
              ElevatedButton(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => LosnummerWalzenDialog(
                      initialLosnummer: _losnummer,
                      totalDuration:
                          const Duration(milliseconds: 3500),
                      holdDuration: const Duration(seconds: 5),
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
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: const Text(
                  'Walze',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Beschriftungen GS / SUPER 6 / Spiel77
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _gluecksspirale = !_gluecksspirale);
                },
                child: Text(
                  '‾‾ GLÜCKSSPIRALE ‾‾',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        _gluecksspirale ? Colors.white : Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _super6 = !_super6);
                },
                child: Text(
                  '__ SUPER 6 __',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _super6 ? Colors.white : Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _spiel77 = !_spiel77);
                },
                child: Text(
                  '——— SPIEL 77 ——',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _spiel77 ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Superzahl',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
