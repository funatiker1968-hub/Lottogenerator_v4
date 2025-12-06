import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/models/lotto_data.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';

class HistoriePage extends StatefulWidget {
  const HistoriePage({Key? key}) : super(key: key);

  @override
  _HistoriePageState createState() => _HistoriePageState();
}

class _HistoriePageState extends State<HistoriePage> {
  List<LottoZiehung> ziehungen = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _ladeZiehungen();
  }

  Future<void> _ladeZiehungen() async {
    setState(() => isLoading = true);
    
    try {
      final geladeneZiehungen = await EinfacheLottoDatenbank.holeAlleZiehungen();
      
      setState(() {
        ziehungen = geladeneZiehungen;
        isLoading = false;
      });
      
      print('📊 ${ziehungen.length} Ziehungen geladen');
    } catch (error) {
      print('❌ Fehler beim Laden: $error');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fuegeBeispielDatenHinzu() async {
    setState(() => isLoading = true);
    
    for (var ziehung in BeispielDaten.beispielZiehungen) {
      await EinfacheLottoDatenbank.fuegeZiehungHinzu(ziehung);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await _ladeZiehungen();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beispiel-Daten hinzugefügt!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _loescheAlleDaten() async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten löschen?'),
        content: const Text('Möchten Sie wirklich alle Daten löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (bestaetigt == true) {
      await EinfacheLottoDatenbank.loescheAlleDaten();
      await _ladeZiehungen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto Historie'),
        backgroundColor: Colors.blue,
        actions: [
          // NEUER IMPORT-BUTTON
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () {
              Navigator.pushNamed(context, '/lottoimport');
            },
            tooltip: 'Daten aus Web importieren',
          ),
          if (ziehungen.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _loescheAlleDaten,
              tooltip: 'Alle Daten löschen',
            ),
        ],
      ),
      body: Column(
        children: [
          // Statistik-Karten
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Gesamt', ziehungen.length.toString()),
                    _buildStatCard('Letzte', 
                      ziehungen.isNotEmpty 
                        ? ziehungen.first.formatierterDatum 
                        : '-'
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Aktions-Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fuegeBeispielDatenHinzu,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Beispiel-Daten'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _ladeZiehungen,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aktualisieren'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Historische Ziehungen:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Ziehungs-Liste
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ziehungen.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Keine historischen Daten',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Klicken Sie auf "Beispiel-Daten" oder "Web Import"',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: ziehungen.length,
                        itemBuilder: (context, index) {
                          final ziehung = ziehungen[index];
                          return _buildZiehungCard(ziehung);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildZiehungCard(LottoZiehung ziehung) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ziehung.formatierterDatum,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Chip(
                  label: Text(
                    'Super: ${ziehung.superzahl.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Zahlen als Chips anzeigen
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ziehung.zahlen.map((zahl) {
                return Chip(
                  label: Text(
                    zahl.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
