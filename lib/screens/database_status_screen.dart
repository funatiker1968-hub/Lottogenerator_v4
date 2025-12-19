import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';
import 'dart:async';

class DatabaseStatusScreen extends StatefulWidget {
  const DatabaseStatusScreen({super.key});

  @override
  State<DatabaseStatusScreen> createState() => _DatabaseStatusScreenState();
}

class _DatabaseStatusScreenState extends State<DatabaseStatusScreen> {
  final LottoDatabase _db = LottoDatabase();
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  List<String> _logMessages = [];
  final ScrollController _logScrollController = ScrollController();

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logMessages.add('[$timestamp] $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    _addLog('📊 Lade Datenbank-Statistik...');
    final database = await _db.database;

    try {
      final totalCount = await database.rawQuery('SELECT COUNT(*) FROM ziehungen');
      final total = totalCount.first.values.first as int;
      _addLog('✅ Gesamtzahl Ziehungen: $total');

      final typeCounts = await database.rawQuery('''
        SELECT spieltyp, COUNT(*) as count FROM ziehungen GROUP BY spieltyp
      ''');

      final countsMap = <String, int>{};
      for (final row in typeCounts) {
        countsMap[row['spieltyp'] as String] = row['count'] as int;
        _addLog('   ${row['spieltyp']}: ${row['count']} Ziehungen');
      }

      final lastDates = await database.rawQuery('''
        SELECT spieltyp, MAX(datum) as last_date FROM ziehungen GROUP BY spieltyp
      ''');

      final datesMap = <String, String>{};
      for (final row in lastDates) {
        datesMap[row['spieltyp'] as String] = row['last_date'] as String;
        _addLog('   Letztes Datum ${row['spieltyp']}: ${row['last_date']}');
      }

      setState(() {
        _stats = {
          'total': total,
          'countsByType': countsMap,
          'lastDates': datesMap,
          'lastUpdate': DateTime.now().toIso8601String(),
        };
        _loading = false;
      });
      _addLog('✅ Statistik geladen.');
    } catch (e) {
      _addLog('❌ Fehler beim Laden: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _triggerReimport() async {
    _addLog('🔄 Starte kompletten Neu-Import...');
    final database = await _db.database;
    await database.delete('ziehungen');
    _addLog('🗑️  Alte Daten gelöscht.');
    await _db.close();
    final newDb = LottoDatabase();
    _addLog('📥 Öffne neue Datenbank (löst automatischen Import aus)...');
    await newDb.database;
    _addLog('✅ Import-Prozess gestartet.');
    await Future.delayed(const Duration(seconds: 2)); // Kurze Pause für Import
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenbank Status & Import'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Statistik aktualisieren',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => _logMessages.clear()),
            tooltip: 'Log leeren',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status-Karten oben
          Expanded(
            flex: 2,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('📊 Datenbank Übersicht',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Gesamtzahl Ziehungen: ${_stats['total']}'),
                                Text('Letzte Aktualisierung: ${_stats['lastUpdate'].substring(0, 16)}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Details nach Spieltyp:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ..._stats['countsByType'].entries.map((entry) {
                          final spieltyp = entry.key;
                          final count = entry.value;
                          final lastDate = _stats['lastDates'][spieltyp] ?? 'Keine Daten';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(spieltyp == '6aus49'
                                  ? Icons.confirmation_number
                                  : Icons.euro),
                              title: Text(spieltyp == '6aus49' ? 'Lotto 6aus49' : 'Eurojackpot'),
                              subtitle: Text('$count Ziehungen · Letzte: $lastDate'),
                              trailing: Text(count > 0 ? '✅' : '🔄'),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _triggerReimport,
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Datenbank komplett neu importieren'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Log-Ausgabe unten
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[700]!)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Import-Log', style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      Text('${_logMessages.length} Einträge',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: _logMessages.isEmpty
                      ? const Center(
                          child: Text('Keine Logs vorhanden.',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          controller: _logScrollController,
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _logMessages.length,
                          itemBuilder: (context, index) {
                            final message = _logMessages[index];
                            return Text(
                              message,
                              style: TextStyle(
                                color: message.contains('✅')
                                    ? Colors.green[300]
                                    : message.contains('❌')
                                        ? Colors.red[300]
                                        : message.contains('⚠️')
                                            ? Colors.orange[300]
                                            : Colors.grey[300],
                                fontFamily: 'Monospace',
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
