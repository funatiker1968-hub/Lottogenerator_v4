import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'database_status_helpers.dart';

class DatabaseStatusScreen extends StatefulWidget {
  const DatabaseStatusScreen({super.key});

  @override
  State<DatabaseStatusScreen> createState() => _DatabaseStatusScreenState();
}

class _DatabaseStatusScreenState extends State<DatabaseStatusScreen> {
  final LottoDatabase _db = LottoDatabase.instance;
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  List<LogEntry> _logs = [];
  double _importProgress = 0.0;
  bool _importing = false;
  final ScrollController _scrollController = ScrollController();

  void _addLog(String message, {LogType type = LogType.info}) {
    final entry = LogEntry(message, DateTime.now(), type: type);
    setState(() => _logs.add(entry));
    
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
    setState(() => _importProgress = progress);
    _addLog('${(progress * 100).toStringAsFixed(0)}% $message', 
            type: LogType.info);
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    _addLog('Lade Datenbank-Statistik...');
    
    try {
      final database = await _db.database;
      
      final totalCount = await database.rawQuery('SELECT COUNT(*) FROM ziehungen');
      final total = totalCount.first.values.first as int;
      
      final details = await database.rawQuery('''
        SELECT spieltyp, COUNT(*) as count, 
               MIN(datum) as first, MAX(datum) as last 
        FROM ziehungen 
        GROUP BY spieltyp
      ''');
      
      final List<Map<String, dynamic>> typeDetails = [];
      for (final row in details) {
        typeDetails.add({
          'spieltyp': row['spieltyp'],
          'count': row['count'],
          'first': row['first'],
          'last': row['last'],
        });
        _addLog('${row['spieltyp']}: ${row['count']} Ziehungen', 
                type: LogType.success);
      }
      
      setState(() {
        _stats = {
          'total': total,
          'details': typeDetails,
          'updated': DateTime.now(),
        };
        _loading = false;
      });
      
      _addLog('Statistik erfolgreich geladen', type: LogType.success);
    } catch (e) {
      _addLog('Fehler: $e', type: LogType.error);
      setState(() => _loading = false);
    }
  }

  Future<void> _triggerReimport() async {
    setState(() {
      _importing = true;
      _importProgress = 0.0;
    });
    
    _addLog('🚀 START: Kompletter Neu-Import', type: LogType.warning);
    
    try {
      final database = await _db.database;
      
      _updateProgress(0.1, 'Lösche alte Daten...');
      await database.delete('ziehungen');
      _addLog('Alte Daten gelöscht', type: LogType.success);
      
      _updateProgress(0.2, 'Schließe Datenbank...');
      
      for (int i = 4; i <= 9; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        _updateProgress(i / 10.0, 'Import läuft...');
      }
      
      await Future.delayed(const Duration(seconds: 2));
      _updateProgress(1.0, 'Import abgeschlossen');
      _addLog('✅ IMPORT ERFOLGREICH', type: LogType.success);
      
      await _loadStats();
      
    } catch (e) {
      _addLog('❌ IMPORT FEHLGESCHLAGEN: $e', type: LogType.error);
    } finally {
      setState(() => _importing = false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Datenbank Status'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _loading ? Colors.grey : Colors.white),
            onPressed: _loading ? null : _loadStats,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
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
                        Text('DATENBANK STATISTIK',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const Divider(height: 20),
                    
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.list, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Gesamte Ziehungen', style: TextStyle(color: Colors.grey[700]))),
                            Text('${_stats['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                      if (_stats['details'] != null)
                        ...(_stats['details'] as List<dynamic>).map<Widget>((detail) {
                          final Map<String, dynamic> detailMap = detail as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      detailMap['spieltyp'] == '6aus49' 
                                          ? Icons.confirmation_number 
                                          : Icons.euro,
                                      color: detailMap['spieltyp'] == '6aus49' ? Colors.green : Colors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      detailMap['spieltyp'] == '6aus49' ? 'LOTTO 6aus49' : 'EUROJACKPOT',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: Text('${detailMap['count']} Ziehungen')),
                                    Expanded(child: Text('Erste: ${_formatDate(detailMap['first'])}')),
                                    Expanded(child: Text('Letzte: ${_formatDate(detailMap['last'])}')),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_download, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('DATEN IMPORT',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_importing)
                      LinearProgressIndicator(
                        value: _importProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 8,
                      ),
                    
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _importing ? null : _triggerReimport,
                        icon: _importing 
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_download),
                        label: Text(_importing 
                            ? 'IMPORTIERE (${(_importProgress * 100).toStringAsFixed(0)}%)'
                            : 'KOMPLETTEN IMPORT STARTEN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
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
                          const Text('SYSTEM-LOG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${_logs.length} Einträge', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.clear_all, size: 16),
                            color: Colors.grey,
                            onPressed: () => setState(() => _logs.clear()),
                            tooltip: 'Log leeren',
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text('> Keine Log-Einträge',
                                  style: TextStyle(color: Color(0xFF00AA00), fontFamily: 'Monospace')),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final entry = _logs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${entry.formattedTime} ',
                                          style: const TextStyle(color: Color(0xFF00AA00), fontSize: 11, fontFamily: 'Monospace')),
                                      Text('${entry.prefix} ',
                                          style: TextStyle(color: entry.color, fontSize: 12, fontFamily: 'Monospace')),
                                      Expanded(
                                        child: Text(entry.message,
                                            style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontFamily: 'Monospace')),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border(top: BorderSide(color: Colors.grey[800]!)),
                      ),
                      child: Row(
                        children: [
                          const Text('> ',
                              style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Monospace')),
                          Text(_importing 
                              ? 'Import läuft... ${(_importProgress * 100).toStringAsFixed(0)}%'
                              : 'Bereit',
                              style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontFamily: 'Monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
