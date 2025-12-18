import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';

class DatabaseStatusScreen extends StatefulWidget {
  const DatabaseStatusScreen({super.key});

  @override
  State<DatabaseStatusScreen> createState() => _DatabaseStatusScreenState();
}

class _DatabaseStatusScreenState extends State<DatabaseStatusScreen> {
  final LottoDatabase _db = LottoDatabase();
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final database = await _db.database;

    try {
      // 1. Gesamtzahl der Ziehungen
      final totalCount = await database.rawQuery('SELECT COUNT(*) FROM ziehungen');
      final total = totalCount.first.values.first as int;

      // 2. Anzahl nach Spieltyp
      final typeCounts = await database.rawQuery('''
        SELECT spieltyp, COUNT(*) as count FROM ziehungen GROUP BY spieltyp
      ''');

      final countsMap = <String, int>{};
      for (final row in typeCounts) {
        countsMap[row['spieltyp'] as String] = row['count'] as int;
      }

      // 3. Letztes Datum nach Spieltyp
      final lastDates = await database.rawQuery('''
        SELECT spieltyp, MAX(datum) as last_date FROM ziehungen GROUP BY spieltyp
      ''');

      final datesMap = <String, String>{};
      for (final row in lastDates) {
        datesMap[row['spieltyp'] as String] = row['last_date'] as String;
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
    } catch (e) {
      print('Fehler beim Laden der Statistik: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _triggerReimport() async {
    final database = await _db.database;
    await database.delete('ziehungen');
    await _db.close();
    final newDb = LottoDatabase();
    await newDb.database;
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
        ],
      ),
      body: _loading
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
                  const SizedBox(height: 20),
                  const Text('Details nach Spieltyp:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _triggerReimport,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('Datenbank komplett neu importieren'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Achtung: Löscht alle vorhandenen Daten und startet den Import neu.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
