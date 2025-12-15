import 'package:flutter/material.dart';
import '../services/statistics/statistics.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final StatisticsFacade _stats = StatisticsFacade();

  bool _isLoading = false;
  String _output = 'Bereit.\nWähle eine Statistik oder Analyse.';

  Future<void> _runStatistic(String function) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _output = '⏳ Berechne...';
    });

    try {
      final buffer = StringBuffer();

      switch (function) {
        case 'db_status':
          final lotto = await _stats.db.inspect(spieltyp: '6aus49');
          final euro = await _stats.db.inspect(spieltyp: 'eurojackpot');

          buffer.writeln('📊 DATENBANK STATUS\n');
          buffer.writeln('Lotto 6aus49: ${lotto.count} Ziehungen');
          buffer.writeln('  Erste: ${lotto.firstDate ?? "-"}');
          buffer.writeln('  Letzte: ${lotto.lastDate ?? "-"}\n');
          buffer.writeln('Eurojackpot: ${euro.count} Ziehungen');
          buffer.writeln('  Erste: ${euro.firstDate ?? "-"}');
          buffer.writeln('  Letzte: ${euro.lastDate ?? "-"}');
          break;

        case 'top_numbers':
          final freq = await _stats.freq.frequency(
            spieltyp: '6aus49',
            lastNDraws: 0,
            takeNumbersPerDraw: 6,
            euroOffset: 0,
          );

          buffer.writeln('🔥 TOP 10 ZAHLEN (6aus49)');
          for (final e in freq.top(10)) {
            buffer.writeln('  ${e.key}: ${e.value}x');
          }
          break;

        case 'cold_numbers':
          final gaps = await _stats.gap.gaps(
            spieltyp: '6aus49',
            minNumber: 1,
            maxNumber: 49,
            takeNumbersPerDraw: 6,
            euroOffset: 0,
          );

          buffer.writeln('🧊 KÄLTESTE ZAHLEN');
          for (int i = 0; i < gaps.length && i < 10; i++) {
            final g = gaps[i];
            buffer.writeln('  ${g.number}: ${g.currentGap} Ziehungen');
          }
          break;

        case 'generate_tip':
          final tip = await _stats.gen.generateLotto6aus49(
            lastN: 50,
            bias: 1.3,
            includeSuperzahl: false,
          );

          buffer.writeln('🎯 INTELLIGENTER TIPP');
          buffer.writeln('Zahlen: ${tip.numbers.sublist(0, 6).join(", ")}');
          buffer.writeln('(Basis: letzte 50 Ziehungen)');
          break;

        case 'simulate':
          final summary = await _stats.sim.simulateLotto6aus49(
            tipMain: [1, 2, 3, 4, 5, 6],
            superzahl: null,
          );

          buffer.writeln('🧪 SIMULATION: 1-2-3-4-5-6');
          buffer.writeln('Ziehungen: ${summary.draws}');
          summary.histogram.forEach((k, v) {
            buffer.writeln('  $k Richtige: ${v}x');
          });
          break;

        case 'ej_stats':
          final mainFreq = await _stats.ej.frequencyMain();
          final euroFreq = await _stats.ej.frequencyEuro();

          buffer.writeln('🇪🇺 EUROJACKPOT STATISTIK\n');
          buffer.writeln('Top 5 Hauptzahlen:');
          for (final e in mainFreq.top(5)) {
            buffer.writeln('  ${e.key}: ${e.value}x');
          }

          buffer.writeln('\nTop 3 Eurozahlen:');
          for (final e in euroFreq.top(3)) {
            buffer.writeln('  ${e.key}: ${e.value}x');
          }
          break;

        default:
          buffer.writeln('❌ Unbekannte Funktion');
      }

      setState(() {
        _output = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _output = '❌ Fehler:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Analyse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn('📊 DB Status', 'db_status'),
                _btn('🔥 Top Zahlen', 'top_numbers'),
                _btn('🧊 Kalte Zahlen', 'cold_numbers'),
                _btn('🎯 Smart Tipp', 'generate_tip'),
                _btn('🧪 Simulation', 'simulate'),
                _btn('🇪🇺 EJ Stats', 'ej_stats'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _output,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, String fn) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _runStatistic(fn),
      child: Text(label),
    );
  }
}
