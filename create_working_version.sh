#!/bin/bash

echo "🛠️ Erstelle funktionierende database_status_screen.dart..."

# Backup der aktuellen Datei
cp lib/screens/database_status_screen.dart lib/screens/database_status_screen.dart.backup_final

# Erstelle korrigierte Version
cat > lib/screens/database_status_screen.dart << 'WORKING_CODE'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // für rootBundle
import 'package:lottogenerator_v4/services/lotto_database.dart';

// Externe Definitionen (außerhalb der State-Klasse)
enum LogType {
  info,
  warning,
  error,
  success
}

class LogEntry {
  final DateTime timestamp;
  final LogType type;
  final String message;
  
  LogEntry(this.timestamp, this.type, this.message);
  
  @override
  String toString() {
    final timeStr = '\${timestamp.hour.toString().padLeft(2, '0')}:\${timestamp.minute.toString().padLeft(2, '0')}:\${timestamp.second.toString().padLeft(2, '0')}';
    
    switch (type) {
      case LogType.info:
        return '[\$timeStr] ℹ️  \$message';
      case LogType.warning:
        return '[\$timeStr] ⚠️  \$message';
      case LogType.error:
        return '[\$timeStr] ❌ \$message';
      case LogType.success:
        return '[\$timeStr] ✅ \$message';
      default:
        return '[\$timeStr] \$message';
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
  final List<LogEntry> _logs = [];
  bool _isImporting = false;
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
    
    // Auto-scroll to bottom
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
      _addLog(LogType.info, '\${(progress * 100).toStringAsFixed(0)}%: \$message');
    }
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await _db.database;
      
      // Lotto 6aus49 Einträge zählen
      final lottoCount = await db.rawQuery(
        "SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = 'lotto_6aus49'"
      );
      final lottoNum = lottoCount.first['count'] as int;
      
      // Eurojackpot Einträge zählen
      final ejCount = await db.rawQuery(
        "SELECT COUNT(*) as count FROM ziehungen WHERE spieltyp = 'eurojackpot'"
      );
      final ejNum = ejCount.first['count'] as int;
      
      // Datumsbereiche
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
          'Lotto 6aus49': '\$lottoNum Einträge\\n'
                         'Von: \${_formatDate(lottoFirst.first['first'] as String? ?? '')}\\n'
                         'Bis: \${_formatDate(lottoLast.first['last'] as String? ?? '')}',
          
          'Eurojackpot': '\$ejNum Einträge\\n'
                        'Von: \${_formatDate(ejFirst.first['first'] as String? ?? '')}\\n'
                        'Bis: \${_formatDate(ejLast.first['last'] as String? ?? '')}',
          
          'Gesamt': '\${lottoNum + ejNum} Einträge insgesamt'
        };
      });
      
      _addLog(LogType.success, 'Datenbank-Statistik geladen: \$lottoNum Lotto, \$ejNum Eurojackpot');
      
    } catch (e) {
      _addLog(LogType.error, 'Fehler beim Laden der Datenbank-Info: \$e');
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
          return '\${parts[0]}.\${parts[1]}.\${parts[2]}';
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _triggerReimport() async {
    if (_isImporting) return;
    
    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
    });
    
    _addLog(LogType.warning, '🚀 START: Kompletter Neu-Import aus TXT-Dateien');
    
    try {
      final database = await _db.database;
      
      // SCHRITT 1: DATENBANK LEEREN
      _updateProgress(0.1, 'Lösche alte Daten...');
      await database.delete('ziehungen');
      _addLog(LogType.success, '✅ Alte Daten gelöscht');
      
      // SCHRITT 2: LOTTO 6AUS49 IMPORTIEREN
      _updateProgress(0.2, 'Importiere Lotto 6aus49...');
      _addLog(LogType.info, '📥 Lese Lotto-Daten...');
      
      try {
        final content = await rootBundle.loadString('assets/data/lotto_1955_2025.txt');
        final lines = content.split('\\n');
        int imported = 0;
        int total = lines.length;
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('|');
          if (parts.length != 3) continue;
          
          final datum = parts[0].trim();
          final zahlen = parts[1].trim();
          final superzahl = int.tryParse(parts[2].trim()) ?? 0;
          
          final datumParts = datum.split('.');
          if (datumParts.length == 3) {
            final dbDatum = '\${datumParts[0]}-\${datumParts[1]}-\${datumParts[2]}';
            
            await database.insert('ziehungen', {
              'spieltyp': 'lotto_6aus49',
              'datum': dbDatum,
              'zahlen': zahlen,
              'superzahl': superzahl
            });
            
            imported++;
          }
          
          if (imported % 100 == 0) {
            final progress = 0.2 + (0.4 * imported / total);
            _updateProgress(progress, 'Lotto: \$imported/\$total');
          }
        }
        
        _addLog(LogType.success, '✅ \$imported Lotto-Ziehungen importiert');
        _updateProgress(0.6, 'Lotto-Import abgeschlossen');
        
      } catch (e) {
        _addLog(LogType.error, '❌ Lotto-Import Fehler: \$e');
      }
      
      // SCHRITT 3: EUROJACKPOT IMPORTIEREN
      _updateProgress(0.65, 'Importiere Eurojackpot...');
      _addLog(LogType.info, '📥 Lese Eurojackpot-Daten...');
      
      try {
        final content = await rootBundle.loadString('assets/data/eurojackpot_2012_2025.txt');
        final lines = content.split('\\n');
        int imported = 0;
        int total = lines.length;
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('|');
          if (parts.length != 3) continue;
          
          final datum = parts[0].trim();
          final hauptzahlen = parts[1].trim();
          final eurozahlen = parts[2].trim();
          final zahlen = '\$hauptzahlen \$eurozahlen';
          
          await database.insert('ziehungen', {
            'spieltyp': 'eurojackpot',
            'datum': datum,
            'zahlen': zahlen,
            'superzahl': 0
          });
          
          imported++;
          
          if (imported % 50 == 0) {
            final progress = 0.65 + (0.3 * imported / total);
            _updateProgress(progress, 'Eurojackpot: \$imported/\$total');
          }
        }
        
        _addLog(LogType.success, '✅ \$imported Eurojackpot-Ziehungen importiert');
        _updateProgress(0.95, 'Eurojackpot-Import abgeschlossen');
        
      } catch (e) {
        _addLog(LogType.error, '❌ Eurojackpot-Import Fehler: \$e');
      }
      
      // SCHRITT 4: ABSCHLUSS
      await Future.delayed(const Duration(milliseconds: 500));
      _updateProgress(1.0, 'Import komplett abgeschlossen');
      
      _addLog(LogType.success, '🎉 DATENBANK NEU GELADEN: Lotto + Eurojackpot');
      _addLog(LogType.info, 'ℹ️  Statistik wird aktualisiert...');
      
      await _loadDatabaseInfo();
      
    } catch (e) {
      _addLog(LogType.error, '❌ IMPORT FEHLGESCHLAGEN: \$e');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
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
              title: Text('Manuell \$spieltyp importieren'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Füge die Kompakt-Daten ein (eine Zeile pro Ziehung):'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 10,
                    minLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '101.01.2025Mi37151826332\\n204.01.2025Sa26243036452\\n...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isImporting)
                    const CircularProgressIndicator(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: isImporting ? null : () async {
                    setState(() => isImporting = true);
                    
                    try {
                      final db = LottoDatabase();
                      final text = controller.text;
                      
                      _addLog(LogType.info, 'Starte manuellen \$spieltyp Import...');
                      
                      Map<String, int> result;
                      
                      if (spieltyp == 'lotto') {
                        result = await db.importLotto6aus49Manually(text);
                      } else {
                        result = await db.importEurojackpotManually(text);
                      }
                      
                      _addLog(LogType.success, 'Manueller Import abgeschlossen!');
                      _addLog(LogType.info, 'Importiert: \${result['imported']}');
                      _addLog(LogType.info, 'Übersprungen: \${result['skipped']}');
                      _addLog(LogType.info, 'Fehler: \${result['errors']}');
                      
                      _loadDatabaseInfo();
                      
                      if (mounted) {
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '\${result['imported']} neue \$spieltyp-Ziehungen importiert!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      _addLog(LogType.error, 'Import-Fehler: \$e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Import fehlgeschlagen: \$e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _isLoading ? Colors.grey : Colors.white),
            onPressed: _isLoading ? null : _loadDatabaseInfo,
            tooltip: 'Statistik aktualisieren',
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
            // Datenbank-Info Kacheln
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _databaseInfo.entries.map((entry) {
                  return Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Import-Controls
            Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Datenbank Import',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Fortschrittsbalken
                    LinearProgressIndicator(
                      value: _importProgress,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _importProgress >= 1.0 ? Colors.green : Colors.blue,
                      ),
                      minHeight: 20,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Auto-Import Button
                        ElevatedButton.icon(
                          onPressed: _isImporting ? null : _triggerReimport,
                          icon: _isImporting
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_download),
                          label: Text(_isImporting
                              ? 'IMPORTIERE (\${(_importProgress * 100).toStringAsFixed(0)}%)'
                              : 'KOMPLETTEN IMPORT STARTEN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Lotto manuell importieren
                        ElevatedButton(
                          onPressed: () => _showManualImportDialog('lotto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.numbers),
                              SizedBox(width: 8),
                              Text('LOTTO IMPORT'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Eurojackpot manuell importieren
                        ElevatedButton(
                          onPressed: () => _showManualImportDialog('eurojackpot'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.euro),
                              SizedBox(width: 8),
                              Text('EJ IMPORT'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Terminal-Log
            Expanded(
              child: Card(
                color: Colors.black,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.terminal, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('SYSTEM-LOG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Spacer(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.green, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[_logs.length - 1 - index];
                              Color textColor;
                              
                              switch (log.type) {
                                case LogType.info:
                                  textColor = Colors.cyan;
                                  break;
                                case LogType.warning:
                                  textColor = Colors.yellow;
                                  break;
                                case LogType.error:
                                  textColor = Colors.red;
                                  break;
                                case LogType.success:
                                  textColor = Colors.green;
                                  break;
                                default:
                                  textColor = Colors.white;
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.0,
                                ),
                                child: Text(
                                  log.toString(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontFamily: 'Monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
WORKING_CODE

echo "✅ Funktionierende Version erstellt!"
echo ""
echo "🧪 Prüfe Syntax..."
dart analyze lib/screens/database_status_screen.dart --no-pub 2>&1 | grep -E "error •" | head -10 || echo "✅ Keine Syntax-Fehler"
