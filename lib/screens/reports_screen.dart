import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../database/db_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Term> _terms = [];
  Term? _selectedTerm;
  List<Exam> _exams = [];
  Exam? _selectedExam;
  Map<String, dynamic>? _performance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final terms = await DBHelper.instance.getTerms();
    setState(() {
      _terms = terms;
      _selectedTerm = terms.isNotEmpty ? terms.first : null;
    });
    if (_selectedTerm != null) {
      await _loadExams();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadExams() async {
    setState(() => _loading = true);
    final exams = await DBHelper.instance.getExams(termId: _selectedTerm!.id!);
    setState(() {
      _exams = exams;
      _selectedExam = exams.isNotEmpty ? exams.first : null;
    });
    if (_selectedExam != null) {
      await _loadPerformance();
    } else {
      setState(() {
        _performance = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadPerformance() async {
    setState(() => _loading = true);
    final perf = await DBHelper.instance.getExamPerformance(_selectedExam!.id!);
    setState(() {
      _performance = perf;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports — Class Performance')),
      body: _terms.isEmpty
          ? const Center(child: Text('No terms set up yet.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Term>(
                    value: _selectedTerm,
                    decoration: const InputDecoration(
                      labelText: 'Term',
                      border: OutlineInputBorder(),
                    ),
                    items: _terms
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('${t.name} — ${t.session}'),
                            ))
                        .toList(),
                    onChanged: (t) {
                      setState(() => _selectedTerm = t);
                      _loadExams();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_exams.isNotEmpty)
                    DropdownButtonFormField<Exam>(
                      value: _selectedExam,
                      decoration: const InputDecoration(
                        labelText: 'Exam (subject & class)',
                        border: OutlineInputBorder(),
                      ),
                      items: _exams
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('${e.subject} — ${e.className}'),
                              ))
                          .toList(),
                      onChanged: (e) {
                        setState(() => _selectedExam = e);
                        _loadPerformance();
                      },
                    )
                  else
                    const Text('No exams for this term yet.'),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_performance != null && (_performance!['count'] as int) > 0)
                    _buildPerformanceCharts()
                  else if (_selectedExam != null)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No scores recorded for this exam yet.'),
                    )),
                ],
              ),
            ),
    );
  }

  Widget _buildPerformanceCharts() {
    final avg = _performance!['average'] as double;
    final count = _performance!['count'] as int;
    final dist = Map<String, int>.from(_performance!['gradeDistribution'] as Map);
    final grades = ['A', 'B', 'C', 'D', 'E', 'F'];
    final colors = {
      'A': Colors.green,
      'B': Colors.lightGreen,
      'C': Colors.orange,
      'D': Colors.deepOrange,
      'E': Colors.deepOrange.shade700,
      'F': Colors.red,
    };
    final maxCount = dist.values.isEmpty
        ? 1
        : dist.values.reduce((a, b) => a > b ? a : b).clamp(1, 1000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Class Average: ${avg.toStringAsFixed(1)} / ${_selectedExam!.maxScore.toInt()}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('$count student(s) scored', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Grade Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxCount + 1).toDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= grades.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(grades[idx], style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(grades.length, (i) {
                final g = grades[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (dist[g] ?? 0).toDouble(),
                      color: colors[g],
                      width: 28,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
