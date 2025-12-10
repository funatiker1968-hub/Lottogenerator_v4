import 'package:flutter/material.dart';

import '../services/lotto_euro_importer.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _lottoStartController = TextEditingController(text: '1955');
  final _lottoEndController = TextEditingController(text: '2025');
  final _euroStartController = TextEditingController(text: '2012');
  final _euroEndController = TextEditingController(text: '2025');

  final LottoEuroImporter _importer = LottoEuroImporter();

  double _lottoProgress = 0.0;
  double _euroProgress = 0.0;
  double _totalProgress = 0.0;
  String _phase = 'Bereit';
  String _status = '';

  bool _isRunning = false;
  final List<String> _logLines = [];

  @override
  void dispose() {
    _lottoStartController.dispose();
    _lottoEndController.dispose();
    _euroStartController.dispose();
    _euroEndController.dispose();
    super.dispose();
  }

  void _addLog(String line) {
    setState(() {
      _logLines.add(line);
      if (_logLines.length > 300) {
        _logLines.removeRange(0, _logLines.length - 300);
      }
    });
  }

  void _updateProgress(ImportProgress p) {
    setState(() {
      _lottoProgress = p.lottoProgress;
      _euroProgress = p.euroProgress;
      _totalProgress = p.totalProgress;
      _phase = p.phase;
      _status = p.message;
    });
  }

  Future<void> _startImport() async {
    if (_isRunning) return;

    final lottoStart = int.tryParse(_lottoStartController.text) ?? 1955;
    final lottoEnd = int.tryParse(_lottoEndController.text) ?? DateTime.now().year;
    final euroStart = int.tryParse(_euroStartController.text) ?? 2012;
    final euroEnd = int.tryParse(_euroEndController.text) ?? DateTime.now().year;

    setState(() {
      _isRunning = true;
      _lottoProgress = 0.0;
      _euroProgress = 0.0;
      _totalProgress = 0.0;
      _phase = 'Initialisiere';
      _status = 'Starte Import…';
      _logLines.clear();
    });

    try {
      await _importer.importiereAlles(
        lottoStartJahr: lottoStart,
        lottoEndJahr: lottoEnd,
        euroStartJahr: euroStart,
        euroEndJahr: euroEnd,
        onProgress: _updateProgress,
        onLog: _addLog,
      );
    } catch (e) {
      _addLog('❌ Fehler im Import: $e');
      setState(() {
        _status = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daten-Import'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Eingabe-Bereich
            Row(
              children: [
                Expanded(
                  child: _buildYearField(
                    label: 'Lotto Startjahr',
                    controller: _lottoStartController,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildYearField(
                    label: 'Lotto Endjahr',
                    controller: _lottoEndController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildYearField(
                    label: 'Eurojackpot Startjahr',
                    controller: _euroStartController,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildYearField(
                    label: 'Eurojackpot Endjahr',
                    controller: _euroEndController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Phase: $_phase',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _startImport,
              icon: _isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isRunning ? 'Import läuft…' : 'Import starten'),
            ),
            const SizedBox(height: 16),
            // Drei Balken
            _buildProgressBar(
              label: 'Lotto 6aus49',
              value: _lottoProgress,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _buildProgressBar(
              label: 'Eurojackpot',
              value: _euroProgress,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildProgressBar(
              label: 'Gesamt',
              value: _totalProgress,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            // Konsole
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: _logLines.length,
                      itemBuilder: (context, index) {
                        return Text(_logLines[index]);
                      },
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

  Widget _buildYearField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final percent = (value.clamp(0.0, 1.0) * 100).toStringAsFixed(0);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
