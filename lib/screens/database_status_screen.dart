import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'package:lottogenerator_v4/services/auto_update_service.dart';

enum LogType { info, success, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogType type;
  final String message;

  LogEntry(this.timestamp, this.type, this.message);

  @override
  String toString() {
    final time = '[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}]';
    switch (type) {
      case LogType.info:
        return '$time ℹ️ $message';
      case LogType.success:
        return '$time ✅ $message';
      case LogType.warning:
        return '$time ⚠️ $message';
      case LogType.error:
        return '$time ❌ $message';
    }
  }
}

class DatabaseStatusScreen extends StatefulWidget {
  const DatabaseStatusScreen({super.key});

  @override
  _DatabaseStatusScreenState createState() => _DatabaseStatusScreenState();
}

class _DatabaseStatusScreenState extends State<DatabaseStatusScreen> {
  final LottoDatabase _db = LottoDatabase();
  final AutoUpdateService _updateService = AutoUpdateService();
  final List<LogEntry> _logs = [];
  bool _isImporting = false;
  bool _isUpdating = false;
  double _importProgress = 0.0;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  Map<String, String> _databaseInfo = {
    'Lotto 6aus49': 'Lädt...',
    'Eurojackpot': 'Lädt...',
    'Gesamt': 'Lädt...'
  };

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
    _addLog(LogType.info, 'Datenbank Status gestartet');
    _addLog(LogType.info, 'Verbindung zu SQLite-Datenbank hergestellt');
    _addLog(LogType.success, 'Datenbank ist bereit');
  }

  void _addLog(LogType type, String message) {
    setState(() {
      _logs.add(LogEntry(DateTime.now(), type, message));
      if (_logs.length > 100) {
        _logs.removeAt(0);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateProgress(double progress, String message) {
    if (mounted) {
      setState(() {
        _importProgress = progress;
      });
      _addLog(LogType.info, '${(progress * 100).toStringAsFixed(0)}%: $message');
    }
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() => _isLoading = true);

    try {
      final db = await _db.database;

      final lottoCount = await db.rawQuery(
        "SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = 'lotto_6aus49'"
      );
      final lottoNum = lottoCount.first['count'] as int;

      final ejCount = await db.rawQuery(
        "SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = 'eurojackpot'"
      );
      final ejNum = ejCount.first['count'] as int;

      final lottoFirst = await db.rawQuery(
        "SELECT MIN(datum) as first FROM ziehungen WHERE spieltyp = 'lotto_6aus49'"
      );
      final lottoLast = await db.rawQuery(
        "SELECT MAX(datum) as last FROM ziehungen WHERE spieltyp = 'lotto_6aus49'"
      );

      final ejFirst = await db.rawQuery(
        "SELECT MIN(datum) as first FROM ziehungen WHERE spieltyp = 'eurojackpot'"
      );
      final ejLast = await db.rawQuery(
        "SELECT MAX(datum) as last FROM ziehungen WHERE spieltyp = 'eurojackpot'"
      );

      setState(() {
        _databaseInfo = {
          'Lotto 6aus49': '$lottoNum Einträge\n'
                         'Von: ${_formatDate(lottoFirst.first['first'] as String? ?? '')}\n'
                         'Bis: ${_formatDate(lottoLast.first['last'] as String? ?? '')}',
          'Eurojackpot': '$ejNum Einträge\n'
                        'Von: ${_formatDate(ejFirst.first['first'] as String? ?? '')}\n'
                        'Bis: ${_formatDate(ejLast.first['last'] as String? ?? '')}',
          'Gesamt': '${lottoNum + ejNum} Einträge insgesamt'
        };
      });
      _addLog(LogType.success, 'Datenbank-Info aktualisiert');
    } catch (e) {
      _addLog(LogType.error, 'Fehler beim Laden der Datenbank-Info: $e');
      setState(() {
        _databaseInfo = {
          'Lotto 6aus49': 'Fehler',
          'Eurojackpot': 'Fehler',
          'Gesamt': 'Fehler'
        };
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Unbekannt';
    try {
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return '${parts[0]}.${parts[1]}.${parts[2]}';
        }
      }
      return dateStr;
    } catch (e) {
      return 'Formatfehler';
    }
  }

  Future<void> _performFullImport() async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
    });

    _addLog(LogType.warning, '🚀 START: Kompletter Neu-Import aus TXT-Dateien');

    try {
      final database = await _db.database;

      _updateProgress(0.1, 'Lösche alte Daten...');
      await database.delete('ziehungen');

      _updateProgress(0.2, 'Importiere Lotto 6aus49...');
      final lottoText = await DefaultAssetBundle.of(context)
          .loadString('assets/data/lotto_1955_2025.txt');
      final lottoLines = const LineSplitter().convert(lottoText);
      int lottoImported = 0;
      
      for (int i = 0; i < lottoLines.length; i++) {
        final line = lottoLines[i].trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        
        try {
          await _db.importLotto6aus49Line(line);
          lottoImported++;
        } catch (e) {
          _addLog(LogType.error, 'Fehler in Zeile ${i + 1}: $e');
        }
        
        if (i % 100 == 0) {
          _updateProgress(0.2 + 0.5 * (i / lottoLines.length), 
                         'Lotto: $lottoImported/$lottoLines');
        }
      }

      _updateProgress(0.7, 'Importiere Eurojackpot...');
      final ejText = await DefaultAssetBundle.of(context)
          .loadString('assets/data/eurojackpot_2012_2025.txt');
      final ejLines = const LineSplitter().convert(ejText);
      int ejImported = 0;
      
      for (int i = 0; i < ejLines.length; i++) {
        final line = ejLines[i].trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        
        try {
          await _db.importEurojackpotLine(line);
          ejImported++;
        } catch (e) {
          _addLog(LogType.error, 'Fehler in Zeile ${i + 1}: $e');
        }
        
        if (i % 50 == 0) {
          _updateProgress(0.7 + 0.3 * (i / ejLines.length), 
                         'Eurojackpot: $ejImported/$ejLines');
        }
      }

      _updateProgress(1.0, 'Import abgeschlossen!');
      _addLog(LogType.success, '✅ IMPORT ERFOLGREICH: $lottoImported Lotto + $ejImported Eurojackpot Einträge');
      
      await _loadDatabaseInfo();
      
    } catch (e) {
      _addLog(LogType.error, '❌ FEHLER beim Import: $e');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _performAutoUpdate() async {
    if (_isUpdating || _isImporting) return;

    setState(() => _isUpdating = true);
    _addLog(LogType.warning, '🔄 Starte automatisches Update...');

    try {
      final result = await _updateService.updateCurrentYear();

      final imported = result['imported'] ?? 0;
      final errors = result['errors'] ?? 0;

      if (errors == 0 && imported > 0) {
        _addLog(LogType.success, '✅ UPDATE ERFOLGREICH: $imported neue Ziehungen importiert');
      } else if (imported == 0) {
        _addLog(LogType.info, 'ℹ️ Keine neuen Ziehungen gefunden');
      } else {
        _addLog(LogType.warning, '⚠️ Update mit $errors Fehlern abgeschlossen');
      }

      await _loadDatabaseInfo();
    } catch (e) {
      _addLog(LogType.error, '❌ FEHLER beim Update: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showManualImportDialog(String spieltyp) {
    final controller = TextEditingController();
    bool isImporting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Manuell $spieltyp importieren'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Füge die Kompakt-Daten ein (eine Zeile pro Ziehung):'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '101.01.2025Mi37151826332\n102.01.2025Do4152930382\n...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: isImporting ? null : () async {
                    setState(() => isImporting = true);

                    try {
                      final text = controller.text;
                      _addLog(LogType.info, 'Starte manuellen $spieltyp Import...');

                      Map<String, int> result;

                      if (spieltyp == 'lotto') {
                        result = await _db.importLotto6aus49Manually(text);
                      } else {
                        result = await _db.importEurojackpotManually(text);
                      }

                      final imported = result['imported'] ?? 0;
                      final errors = result['errors'] ?? 0;

                      if (errors == 0 && imported > 0) {
                        _addLog(LogType.success, '✅ Manueller $spieltyp Import: $imported neue Einträge');
                        await _loadDatabaseInfo();
                      } else if (imported == 0) {
                        _addLog(LogType.info, 'ℹ️ Keine neuen $spieltyp Einträge');
                      } else {
                        _addLog(LogType.warning, '⚠️ $spieltyp Import mit $errors Fehlern');
                      }

                      Navigator.pop(context);
                    } catch (e) {
                      _addLog(LogType.error, '❌ FEHLER beim manuellen Import: $e');
                    } finally {
                      if (mounted) {
                        setState(() => isImporting = false);
                      }
                    }
                  },
                  child: const Text('Importieren'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenbank Status & Import'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDatabaseInfo,
            tooltip: 'Datenbank-Info aktualisieren',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() => _logs.clear());
              _addLog(LogType.info, 'Logs geleert');
            },
            tooltip: 'Logs löschen',
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.grey[900],
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.count(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: _databaseInfo.entries.map((entry) {
                          return Card(
                            color: Colors.grey[800],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 4,
              color: Colors.grey[800],
              child: _isImporting
                  ? LinearProgressIndicator(
                      value: _importProgress,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.greenAccent,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 2),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text(
                      'TERMINAL LOGS',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.greenAccent, height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color color;
                          switch (log.type) {
                            case LogType.info:
                              color = Colors.white70;
                              break;
                            case LogType.success:
                              color = Colors.greenAccent;
                              break;
                            case LogType.warning:
                              color = Colors.amber;
                              break;
                            case LogType.error:
                              color = Colors.redAccent;
                              break;
                          }
                          return Text(
                            log.toString(),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontFamily: 'Monospace',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('VOLL-IMPORT'),
                    onPressed: _isImporting ? null : _performFullImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('AUTO-UPDATE'),
                    onPressed: _isUpdating ? null : _performAutoUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.input),
                    label: const Text('MAN. LOTTO'),
                    onPressed: _isImporting ? null : () => _showManualImportDialog('lotto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.input),
                    label: const Text('MAN. EJ'),
                    onPressed: _isImporting ? null : () => _showManualImportDialog('eurojackpot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
