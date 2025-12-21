import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'dart:async';

// Hilfsklassen außerhalb der Hauptklasse
@immutable
class LogEntry {
  final String message;
  final DateTime timestamp;
  final LogType type;

  const LogEntry({
    required this.message,
    required this.timestamp,
    this.type = LogType.info,
  });

  String get formattedTime => 
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';

  Color get color {
    switch (type) {
      case LogType.success: return const Color(0xFF4CAF50);
      case LogType.error: return const Color(0xFFF44336);
      case LogType.warning: return const Color(0xFFFF9800);
      case LogType.system: return const Color(0xFF2196F3);
      default: return const Color(0xFFCCCCCC);
    }
  }

  IconData get icon {
    switch (type) {
      case LogType.success: return Icons.check_circle;
      case LogType.error: return Icons.error;
      case LogType.warning: return Icons.warning;
      case LogType.system: return Icons.info;
      default: return Icons.info;
    }
  }
}

enum LogType { info, success, error, warning, system }

class DatabaseStatusScreen extends StatefulWidget {
  const DatabaseStatusScreen({super.key});

  @override
  State<DatabaseStatusScreen> createState() => _DatabaseStatusScreenState();
}

class _DatabaseStatusScreenState extends State<DatabaseStatusScreen> {
  final LottoDatabase _db = LottoDatabase();
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  List<LogEntry> _logMessages = [];
  final ScrollController _logScrollController = ScrollController();
  double _importProgress = 0.0;
  bool _importing = false;

  void _addLog(String message, {LogType type = LogType.info}) {
    final entry = LogEntry(
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    
    setState(() {
      _logMessages.add(entry);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateImportProgress(double progress, String message) {
    setState(() {
      _importProgress = progress;
    });
    _addLog('📊 $message (${(progress * 100).toStringAsFixed(0)}%)', 
            type: LogType.system);
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    _addLog('Lade Datenbank-Statistik...', type: LogType.system);
    
    try {
      final database = await _db.database;
      final totalCount = await database.rawQuery('SELECT COUNT(*) FROM ziehungen');
      final total = totalCount.first.values.first as int;
      
      final typeCounts = await database.rawQuery('''
        SELECT spieltyp, COUNT(*) as count FROM ziehungen GROUP BY spieltyp
      ''');
      
      final countsMap = <String, int>{};
      for (final row in typeCounts) {
        countsMap[row['spieltyp'] as String] = row['count'] as int;
      }
      
      final lastDates = await database.rawQuery('''
        SELECT spieltyp, MAX(datum) as last_date FROM ziehungen GROUP BY spieltyp
      ''');
      
      final datesMap = <String, String>{};
      for (final row in lastDates) {
        final dateStr = row['last_date'] as String;
        final date = DateTime.parse(dateStr);
        datesMap[row['spieltyp'] as String] = 
            '${date.day.toString().padLeft(2, '0')}.'
            '${date.month.toString().padLeft(2, '0')}.'
            '${date.year}';
      }
      
      setState(() {
        _stats = {
          'total': total,
          'countsByType': countsMap,
          'lastDates': datesMap,
          'lastUpdate': DateTime.now(),
        };
        _loading = false;
      });
      
      _addLog('Datenbank-Statistik erfolgreich geladen', type: LogType.success);
    } catch (e) {
      _addLog('Fehler beim Laden: $e', type: LogType.error);
      setState(() => _loading = false);
    }
  }

  Future<void> _triggerReimport() async {
    setState(() {
      _importing = true;
      _importProgress = 0.0;
    });
    
    _addLog('🚀 Starte kompletten Neu-Import...', type: LogType.system);
    
    try {
      final database = await _db.database;
      
      _updateImportProgress(0.1, 'Lösche alte Daten...');
      await database.delete('ziehungen');
      _addLog('Alte Daten erfolgreich gelöscht', type: LogType.success);
      
      _updateImportProgress(0.2, 'Schließe Datenbank...');
      await _db.close();
      
      _updateImportProgress(0.3, 'Erstelle neue Datenbank...');
      final newDb = LottoDatabase();
      
      _updateImportProgress(0.4, 'Starte automatischen Import...');
      await newDb.database;
      
      // Simuliere Import-Fortschritt
      for (int i = 5; i <= 9; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        _updateImportProgress(i / 10.0, 'Import läuft...');
      }
      
      await Future.delayed(const Duration(seconds: 1));
      _updateImportProgress(1.0, 'Import abgeschlossen');
      
      _addLog('✅ Datenbank-Import erfolgreich abgeschlossen', type: LogType.success);
      
      await _loadStats();
      
    } catch (e) {
      _addLog('❌ Import fehlgeschlagen: $e', type: LogType.error);
    } finally {
      setState(() {
        _importing = false;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
           '${dt.month.toString().padLeft(2, '0')}.'
           '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDatabaseStatsCard() {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    final lastUpdate = _stats['lastUpdate'] is DateTime 
        ? _formatDateTime(_stats['lastUpdate'] as DateTime)
        : '-';
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'DATENBANK STATUS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            
            _buildStatRow('Gesamte Ziehungen', '${_stats['total']}', Icons.list),
            _buildStatRow('Letzte Aktualisierung', lastUpdate, Icons.update),
            
            const SizedBox(height: 16),
            const Text('Spieltypen:', style: TextStyle(fontWeight: FontWeight.bold)),
            
            ..._stats['countsByType'].entries.map((entry) {
              final spieltyp = entry.key;
              final count = entry.value;
              final lastDate = _stats['lastDates'][spieltyp] ?? '-';
              
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: spieltyp == '6aus49' ? Colors.green[100] : Colors.purple[100],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        spieltyp == '6aus49' ? Icons.confirmation_number : Icons.euro,
                        color: spieltyp == '6aus49' ? Colors.green : Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spieltyp == '6aus49' ? 'Lotto 6aus49' : 'Eurojackpot',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text('$count Ziehungen • Letzte: $lastDate',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(
                      count > 0 ? Icons.check_circle : Icons.error_outline,
                      color: count > 0 ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[700]))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTerminalPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                const Text('SYSTEM LOG', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_logMessages.length} entries',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 16),
                  color: Colors.grey,
                  onPressed: () => setState(() => _logMessages.clear()),
                  tooltip: 'Log leeren',
                ),
              ],
            ),
          ),
          
          // Progress bar during import
          if (_importing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: LinearProgressIndicator(
                value: _importProgress,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _importProgress < 0.5 ? Colors.orange : Colors.green),
                minHeight: 6,
              ),
            ),
          
          // Terminal Content
          Expanded(
            child: _logMessages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terminal, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Keine Log-Einträge',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _logMessages.length,
                    itemBuilder: (context, index) {
                      final entry = _logMessages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                entry.formattedTime,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontFamily: 'Monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(entry.icon, size: 12, color: entry.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.message,
                                style: TextStyle(
                                  color: entry.color,
                                  fontSize: 12,
                                  fontFamily: 'Monospace',
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Terminal Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, size: 12, color: Color(0xFFCCCCCC)),
                const SizedBox(width: 6),
                Text(_importing 
                    ? 'Import läuft... (${(_importProgress * 100).toStringAsFixed(0)}%)'
                    : 'Bereit',
                    style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
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
            onPressed: _loading ? null : _loadStats,
            tooltip: 'Statistik aktualisieren',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Database Stats Card
            _buildDatabaseStatsCard(),
            
            const SizedBox(height: 16),
            
            // Import Button with status
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_download, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('DATEN IMPORT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Importiert automatisch historische Daten aus den Textdateien im assets/data/ Verzeichnis.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _importing || _loading ? null : _triggerReimport,
                        icon: _importing 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, 
                                  strokeWidth: 2))
                            : const Icon(Icons.cloud_download),
                        label: Text(_importing 
                            ? 'IMPORTIERE... (${(_importProgress * 100).toStringAsFixed(0)}%)'
                            : 'DATENBANK KOMPLETT NEU IMPORTIEREN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (_importing)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(
                          value: _importProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Terminal Panel
            Expanded(
              child: _buildTerminalPanel(),
            ),
          ],
        ),
      ),
    );
  }
}
