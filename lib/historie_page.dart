import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/models/lotto_data.dart';
import 'package:lottogenerator_v4/services/lotto_database_erweitert.dart';

class HistoriePage extends StatefulWidget {
  const HistoriePage({Key? key}) : super(key: key);

  @override
  State<HistoriePage> createState() => _HistoriePageState();
}

class _HistoriePageState extends State<HistoriePage> {
  List<LottoZiehung> _ziehungen = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ladeDaten();
  }

  Future<void> _ladeDaten() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final daten = await ErweiterteLottoDatenbank.holeLetzteZiehungen(
        spieltyp: "6aus49",
        limit: 20,
      );
      
      setState(() {
        _ziehungen = daten;
        _isLoading = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Historie: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto Historie'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ziehungen.isEmpty
              ? const Center(
                  child: Text('Keine Ziehungen gefunden'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _ziehungen.length,
                  itemBuilder: (context, index) {
                    final ziehung = _ziehungen[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        title: Text(ziehung.formatierterDatum),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Zahlen: ${ziehung.zahlen.join(', ')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Superzahl: ${ziehung.superzahl}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ladeDaten,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
