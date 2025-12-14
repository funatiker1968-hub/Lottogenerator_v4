import 'package:flutter/material.dart';
import '../services/lotto_database_erweitert.dart' as erweiterteDB;
import '../models/lotto_data.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  List<LottoZiehung> _ziehungen = [];
  bool _isLoading = true;
  Map<int, int> _zahlHaeufigkeit = {};

  @override
  void initState() {
    super.initState();
    _ladeStatistiken();
  }

  Future<void> _ladeStatistiken() async {
    setState(() => _isLoading = true);
    
    try {
      // Verwende erweiterteDB statt EinfacheLottoDatenbank
      final daten = await erweiterteDB.ErweiterteLottoDatenbank.holeLetzteZiehungen(
        spieltyp: '6aus49',
        limit: 100,
      );
      
      _berechneHaeufigkeiten(daten);
      
      setState(() {
        _ziehungen = daten;
        _isLoading = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Statistiken: $e');
      setState(() => _isLoading = false);
    }
  }

  void _berechneHaeufigkeiten(List<LottoZiehung> ziehungen) {
    final haeufigkeit = <int, int>{};
    
    for (final ziehung in ziehungen) {
      for (final zahl in ziehung.zahlen) {
        if (zahl > 0) {
          haeufigkeit[zahl] = (haeufigkeit[zahl] ?? 0) + 1;
        }
      }
    }
    
    setState(() {
      _zahlHaeufigkeit = haeufigkeit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zahl Häufigkeiten (${_ziehungen.length} Ziehungen)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildHaeufigkeitsListe(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHaeufigkeitsListe() {
    final sortedEntries = _zahlHaeufigkeit.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return ListView.builder(
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final prozent = (entry.value / _ziehungen.length * 100).toStringAsFixed(1);
        
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                '${entry.key}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text('Zahl ${entry.key}'),
            subtitle: LinearProgressIndicator(
              value: entry.value / _ziehungen.length,
              // Korrektur für withOpacity:
              backgroundColor: Colors.grey[300],
              // Verwende Color.fromRGBO statt withOpacity
              color: Color.fromRGBO(
                Theme.of(context).primaryColor.red,
                Theme.of(context).primaryColor.green,
                Theme.of(context).primaryColor.blue,
                0.8,
              ),
            ),
            trailing: Text('$prozent% ($entry.value×)'),
          ),
        );
      },
    );
  }
}
