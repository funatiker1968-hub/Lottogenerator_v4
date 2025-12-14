import 'package:flutter/material.dart';
import '../services/lotto_import_service.dart';
import '../services/eurojackpot_import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final List<String> _log = [];
  bool _running = false;
  String _currentOperation = 'Bereit';
  double? _progress;

  void _status(String msg) {
    if (!mounted) return;
    setState(() {
      _log.add('${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $msg');
    });
  }

  Future<void> _importLotto() async {
    setState(() {
      _log.clear();
      _running = true;
      _currentOperation = 'Importiere Lotto 6aus49...';
      _progress = null;
    });

    try {
      await LottoImportService().import6aus49FromAsset(
        status: _status,
      );
      _status('✅ Lotto-Import erfolgreich abgeschlossen.');
    } catch (e) {
      _status('❌ Fehler Lotto-Import: $e');
    }

    setState(() {
      _running = false;
      _currentOperation = 'Import beendet';
      _progress = null;
    });
  }

  Future<void> _importEurojackpot() async {
    setState(() {
      _log.clear();
      _running = true;
      _currentOperation = 'Importiere Eurojackpot...';
      _progress = null;
    });

    try {
      await EurojackpotImportService.instance.importIfEmpty(
        status: _status,
      );
      _status('✅ Eurojackpot-Import erfolgreich abgeschlossen.');
    } catch (e) {
      _status('❌ Fehler Eurojackpot-Import: $e');
    }

    setState(() {
      _running = false;
      _currentOperation = 'Import beendet';
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenimport'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
      ),
      body: Column(
        children: [
          // --- Fortschrittsanzeige & Status ---
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color.fromRGBO(250, 250, 250, 1),
            child: Column(
              children: [
                if (_running)
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: const Color.fromRGBO(224, 224, 224, 1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color.fromRGBO(76, 175, 80, 1)),
                    minHeight: 8,
                  )
                else
                  Container(height: 8),

                const SizedBox(height: 8),
                Text(
                  _currentOperation,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _running ? const Color.fromRGBO(33, 150, 243, 1) : const Color.fromRGBO(97, 97, 97, 1),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // --- Import-Buttons ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.confirmation_number),
                    label: const Text('Lotto 6aus49 importieren'),
                    onPressed: _running ? null : _importLotto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(21, 101, 192, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.euro),
                    label: const Text('Eurojackpot importieren'),
                    onPressed: _running ? null : _importEurojackpot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(245, 124, 0, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // --- Terminal-Fenster ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(33, 33, 33, 1),
                border: Border.all(color: const Color.fromRGBO(66, 66, 66, 1)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Terminal-Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Import-Log',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Log-Inhalt
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _log.length,
                        itemBuilder: (context, index) {
                          final msg = _log[_log.length - 1 - index];
                          Color textColor = Colors.greenAccent;
                          if (msg.contains('❌')) textColor = Colors.red;
                          if (msg.contains('⚠️')) textColor = Colors.yellow;
                          if (msg.contains('📥')) textColor = Colors.blue;

                          return Text(
                            '> $msg',
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Terminal-Footer
                  if (_log.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${_log.length} Meldungen | Letzte: ${_log.isNotEmpty ? _log.last.split(' - ').last : '-'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontFamily: 'monospace',
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
}
