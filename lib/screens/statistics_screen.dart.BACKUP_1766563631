import 'package:flutter/material.dart';
import '../services/statistics/statistics.dart';

class StatisticsScreen extends StatefulWidget {
  final String spieltyp;
  
  const StatisticsScreen({super.key, this.spieltyp = '6aus49'});
  
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsFacade _stats = StatisticsFacade();
  
  DbSummary? _dbSummary;
  FrequencyResult? _frequencyMain;
  FrequencyResult? _frequencyExtra;
  List<GapStats>? _gapStats;
  RangeDistribution? _rangeDist;
  SumStats? _sumStats;
  Map<String, int>? _parityHist;
  PairResult? _pairResult;
  
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    
    try {
      // 1. Datenbank-Übersicht
      _dbSummary = await _stats.db.inspect(spieltyp: widget.spieltyp);
      
      // 2. Frequenzen
      if (widget.spieltyp == '6aus49') {
        _frequencyMain = await _stats.freq.frequency(
          spieltyp: widget.spieltyp,
          takeNumbersPerDraw: 6,
          euroOffset: 0,
        );
      } else if (widget.spieltyp == 'eurojackpot') {
        _frequencyMain = await _stats.ej.frequencyMain();
        _frequencyExtra = await _stats.ej.frequencyEuro();
      }
      
      // 3. Lücken (nur Top 10 overdue)
      if (widget.spieltyp == '6aus49') {
        final gaps = await _stats.gap.gaps(
          spieltyp: widget.spieltyp,
          minNumber: 1,
          maxNumber: 49,
          takeNumbersPerDraw: 6,
        );
        _gapStats = gaps.take(10).toList();
      } else if (widget.spieltyp == 'eurojackpot') {
        final gapsMain = await _stats.ej.gapsMain();
        _gapStats = gapsMain.take(10).toList();
      }
      
      // 4. Bereichsverteilung
      final buckets = widget.spieltyp == '6aus49'
          ? _stats.defaultLottoBuckets()
          : [
              const RangeBucket('1-10', 1, 10),
              const RangeBucket('11-20', 11, 20),
              const RangeBucket('21-30', 21, 30),
              const RangeBucket('31-40', 31, 40),
              const RangeBucket('41-50', 41, 50),
            ];
      _rangeDist = await _stats.cluster.distribution(
        spieltyp: widget.spieltyp,
        buckets: buckets,
        takeNumbersPerDraw: widget.spieltyp == '6aus49' ? 6 : 5,
      );
      
      // 5. Summen-Statistik
      _sumStats = await _stats.sums.sumStats(
        spieltyp: widget.spieltyp,
        takeNumbersPerDraw: widget.spieltyp == '6aus49' ? 6 : 5,
      );
      
      // 6. Paritätshistogramm (nur für Hauptzahlen)
      _parityHist = await _stats.parity.parityHistogram(
        spieltyp: widget.spieltyp,
        takeNumbersPerDraw: widget.spieltyp == '6aus49' ? 6 : 5,
      );
      
      // 7. Paare (nur für Lotto, optional)
      if (widget.spieltyp == '6aus49') {
        _pairResult = await _stats.pairs.pairs(
          spieltyp: widget.spieltyp,
          takeNumbersPerDraw: 6,
        );
      }
      
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildDbSummaryCard() {
    if (_dbSummary == null) return Container();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Datenbank-Übersicht', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.casino, size: 16),
                const SizedBox(width: 8),
                Text('Spieltyp: ${_dbSummary!.spieltyp}'),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.format_list_numbered, size: 16),
                const SizedBox(width: 8),
                Text('Ziehungen: ${_dbSummary!.count}'),
              ],
            ),
            if (_dbSummary!.firstDate != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('Erste: ${_dbSummary!.firstDate!.toLocal().toString().substring(0, 10)}'),
                ],
              ),
            if (_dbSummary!.lastDate != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('Letzte: ${_dbSummary!.lastDate!.toLocal().toString().substring(0, 10)}'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyCard(String title, FrequencyResult? freq, {int topN = 10}) {
    if (freq == null || freq.counts.isEmpty) return Container();
    
    final top = freq.top(topN);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: top.map((entry) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text(entry.key.toString()),
                  ),
                  label: Text('${entry.value}× (${(entry.value / freq.totalDraws * 100).toStringAsFixed(1)}%)'),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text('Basierend auf ${freq.totalDraws} Ziehungen', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildGapCard() {
    if (_gapStats == null || _gapStats!.isEmpty) return Container();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⏳ Top 10 überfällige Zahlen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._gapStats!.map((gap) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(child: Text('${gap.number}')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${gap.currentGap} Ziehungen her', style: const TextStyle(fontSize: 14)),
                          Text('${gap.occurrences}× insgesamt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (gap.avgGap != null)
                      Text('Ø ${gap.avgGap!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeCard() {
    if (_rangeDist == null) return Container();
    
    final maxValue = _rangeDist!.counts.values.reduce((a, b) => a > b ? a : b);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Verteilung nach Bereichen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._rangeDist!.buckets.map((bucket) {
              final count = _rangeDist!.counts[bucket.label] ?? 0;
              final percentage = maxValue > 0 ? (count / maxValue * 100) : 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(bucket.label),
                        Text('$count'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: maxValue > 0 ? count / maxValue : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage > 70 ? Colors.green : 
                        percentage > 40 ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSumCard() {
    if (_sumStats == null || _sumStats!.countDraws == 0) return Container();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧮 Summen-Statistik', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Minimum', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${_sumStats!.minSum}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Durchschnitt', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_sumStats!.avgSum.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Maximum', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${_sumStats!.maxSum}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Basierend auf ${_sumStats!.countDraws} Ziehungen', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildParityCard() {
    if (_parityHist == null || _parityHist!.isEmpty) return Container();
    
    final total = _parityHist!.values.reduce((a, b) => a + b);
    final sorted = _parityHist!.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text('⚖️ Gerade/Ungerade Verteilung', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...sorted.take(5).map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.key == '3/3' ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$entry.value ($percentage%)'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPairCard() {
    if (_pairResult == null || _pairResult!.counts.isEmpty) return Container();
    
    final topPairs = _pairResult!.top(8);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👥 Häufige Zahlenpaare', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topPairs.map((entry) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.purple[50],
                    child: Text(entry.key.a.toString()),
                  ),
                  label: Text('${entry.key.b} (${entry.value}×)'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistik - ${widget.spieltyp}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Daten neu laden',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDbSummaryCard(),
                      const SizedBox(height: 12),
                      
                      if (widget.spieltyp == '6aus49')
                        _buildFrequencyCard('🎯 Häufigste Zahlen (Lotto 6aus49)', _frequencyMain),
                      
                      if (widget.spieltyp == 'eurojackpot') ...[
                        _buildFrequencyCard('🎯 Häufigste Hauptzahlen (1-50)', _frequencyMain),
                        const SizedBox(height: 12),
                        _buildFrequencyCard('⭐ Häufigste Eurozahlen (1-12)', _frequencyExtra, topN: 5),
                      ],
                      
                      const SizedBox(height: 12),
                      _buildGapCard(),
                      
                      const SizedBox(height: 12),
                      _buildRangeCard(),
                      
                      const SizedBox(height: 12),
                      _buildSumCard(),
                      
                      const SizedBox(height: 12),
                      _buildParityCard(),
                      
                      if (widget.spieltyp == '6aus49') ...[
                        const SizedBox(height: 12),
                        _buildPairCard(),
                      ],
                      
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Alle Daten neu berechnen'),
                        onPressed: _loadAllData,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
