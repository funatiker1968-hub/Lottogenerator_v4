import 'package:flutter/material.dart';
import 'package:lottogenerator_v4/models/lotto_data.dart';
import 'package:lottogenerator_v4/services/lotto_database.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({Key? key}) : super(key: key);

  @override
  _StatistikPageState createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  List<LottoZiehung> ziehungen = [];
  Map<int, int> zahlHaeufigkeiten = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _ladeStatistiken();
  }

  Future<void> _ladeStatistiken() async {
    setState(() => isLoading = true);
    
    try {
      final geladeneZiehungen = await EinfacheLottoDatenbank.holeAlleZiehungen();
      
      // Häufigkeiten berechnen - jetzt korrekt mit allen Zahlen
      final haeufigkeiten = <int, int>{};
      for (var ziehung in geladeneZiehungen) {
        for (var zahl in ziehung.zahlen) {
          haeufigkeiten[zahl] = (haeufigkeiten[zahl] ?? 0) + 1;
        }
      }
      
      setState(() {
        ziehungen = geladeneZiehungen;
        zahlHaeufigkeiten = haeufigkeiten;
        isLoading = false;
      });
      
      print('📊 Statistiken für ${ziehungen.length} Ziehungen geladen');
    } catch (error) {
      print('❌ Fehler beim Laden: $error');
      setState(() => isLoading = false);
    }
  }

  List<MapEntry<int, int>> get topZahlen {
    return zahlHaeufigkeiten.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MapEntry<int, int>> get bottomZahlen {
    return zahlHaeufigkeiten.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto Statistiken'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _ladeStatistiken,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ziehungen.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 64, color: Colors.black),
                      SizedBox(height: 16),
                      Text(
                        'Keine Daten für Statistiken',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fügen Sie zuerst historische Daten hinzu',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Übersicht
                      Card(
                        color: Colors.purple[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Ziehungen', ziehungen.length.toString()),
                              _buildStatCard('Zahlen gesamt', 
                                (ziehungen.length * 6).toString()
                              ),
                              _buildStatCard('Daten von', 
                                '${ziehungen.last.formatierterDatum}\nbis\n${ziehungen.first.formatierterDatum}'
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Text(
                        'Top 10 häufigste Zahlen:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildZahlenListe(topZahlen.take(10).toList(), Colors.green),
                      
                      const SizedBox(height: 20),
                      const Text(
                        'Top 10 seltenste Zahlen:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildZahlenListe(bottomZahlen.take(10).toList(), Colors.orange),
                      
                      const SizedBox(height: 20),
                      const Text(
                        'Verteilung aller Zahlen (1-49):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildAlleZahlenGrid(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildZahlenListe(List<MapEntry<int, int>> zahlen, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: zahlen.map((entry) {
            final prozent = ziehungen.isNotEmpty 
                ? (entry.value / ziehungen.length * 100).toStringAsFixed(1)
                : '0.0';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text(
                  entry.key.toString().padLeft(2, '0'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('Zahl ${entry.key}'),
              subtitle: LinearProgressIndicator(
                value: ziehungen.isNotEmpty && topZahlen.isNotEmpty
                    ? entry.value / (topZahlen.first.value.toDouble())
                    : 0,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              trailing: Text(
                '${entry.value}x ($prozent%)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlleZahlenGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: 49,
      itemBuilder: (context, index) {
        final zahl = index + 1;
        final haeufigkeit = zahlHaeufigkeiten[zahl] ?? 0;
        
        return Container(
          decoration: BoxDecoration(
            color: _getZahlenFarbe(haeufigkeit),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                zahl.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: haeufigkeit > 0 ? Colors.white : Colors.grey,
                ),
              ),
              Text(
                '$haeufigkeit',
                style: TextStyle(
                  fontSize: 10,
                  color: haeufigkeit > 0 ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getZahlenFarbe(int haeufigkeit) {
    if (haeufigkeit == 0) return Colors.grey[300]!;
    if (haeufigkeit <= 5) return Colors.blue[300]!;
    if (haeufigkeit <= 10) return Colors.blue[500]!;
    if (haeufigkeit <= 15) return Colors.blue[700]!;
    return Colors.blue[900]!;
  }
}
