import 'package:flutter/material.dart';
import '../services/advanced_statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String spieltyp;

  const StatisticsScreen({super.key, this.spieltyp = '6aus49'});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AdvancedStatisticsService _service = AdvancedStatisticsService();
  Map<String, dynamic> _analysis = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _loading = true);
    final data = widget.spieltyp == 'eurojackpot'
        ? await _service.getEurojackpotAnalysis()
        : await _service.getFullAnalysis(spieltyp: widget.spieltyp);
    setState(() {
      _analysis = data;
      _loading = false;
    });
  }

  Widget _buildFrequencyTable(Map<int, int> frequencies) {
    final sorted = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DataTable(
      columns: const [
        DataColumn(label: Text('Zahl')),
        DataColumn(label: Text('Häufigkeit')),
      ],
      rows: sorted.take(10).map((entry) {
        return DataRow(cells: [
          DataCell(Text(entry.key.toString())),
          DataCell(Text(entry.value.toString())),
        ]);
      }).toList(),
    );
  }

  Widget _buildRecommendations(List<dynamic> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Empfehlungen (Score):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: recommendations.map<Widget>((rec) {
            return Chip(
              backgroundColor: _getScoreColor(rec['score']),
              label: Text('${rec['number']} (${rec['score']})'),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score > 70) return Colors.green[300]!;
    if (score > 55) return Colors.blue[300]!;
    if (score > 40) return Colors.orange[300]!;
    return Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistik - ${widget.spieltyp}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysis,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _analysis.isEmpty
              ? const Center(child: Text('Keine Daten verfügbar.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gesamtzahl der Ziehungen: ${_analysis['gesamtZiehungen']}'),
                      Text('Letzte Ziehung: ${_analysis['letzteZiehung']}'),
                      const SizedBox(height: 20),
                      const Text('Häufigste Zahlen:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildFrequencyTable(_analysis['frequencies']),
                      const SizedBox(height: 20),
                      if (_analysis['recommendations'] != null)
                        _buildRecommendations(_analysis['recommendations']),
                      if (widget.spieltyp == 'eurojackpot') ...[
                        const SizedBox(height: 20),
                        const Text('Hauptzahlen (1-50):', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildFrequencyTable(_analysis['mainNumbers']),
                        const SizedBox(height: 20),
                        const Text('Eurozahlen (1-10):', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildFrequencyTable(_analysis['euroNumbers']),
                      ],
                    ],
                  ),
                ),
    );
  }
}
