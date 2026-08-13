import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import '../services/report_card_generator.dart';

class ViewResultScreen extends StatefulWidget {
  final AppUser parentUser;
  const ViewResultScreen({super.key, required this.parentUser});

  @override
  State<ViewResultScreen> createState() => _ViewResultScreenState();
}

class _ViewResultScreenState extends State<ViewResultScreen> {
  Student? _student;
  List<Term> _terms = [];
  Term? _selectedTerm;
  List<Map<String, dynamic>> _resultRows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final linkedId = widget.parentUser.linkedStudentId;
    if (linkedId == null) {
      setState(() {
        _error = 'No student is linked to this account. Please contact the school admin.';
        _loading = false;
      });
      return;
    }
    final studentId = int.tryParse(linkedId);
    if (studentId == null) {
      setState(() {
        _error = 'Student link is invalid. Please contact the school admin.';
        _loading = false;
      });
      return;
    }
    final student = await DBHelper.instance.getStudentById(studentId);
    final terms = await DBHelper.instance.getTerms();
    setState(() {
      _student = student;
      _terms = terms;
      _selectedTerm = terms.isNotEmpty ? terms.first : null;
    });
    if (_selectedTerm != null) {
      await _loadResults();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadResults() async {
    if (_student?.id == null || _selectedTerm?.id == null) return;
    setState(() => _loading = true);
    final rows = await DBHelper.instance
        .getResultDetailsForStudent(_student!.id!, _selectedTerm!.id!);
    setState(() {
      _resultRows = rows;
      _loading = false;
    });
  }

  Future<void> _downloadPdf() async {
    if (_student == null || _selectedTerm == null) return;
    if (_resultRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No results to export for this term yet.')),
      );
      return;
    }
    await ReportCardGenerator.generateAndShare(
      student: _student!,
      term: _selectedTerm!,
      resultRows: _resultRows,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('View Result')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_student?.fullName ?? 'View Result')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _downloadPdf,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Download PDF'),
      ),
      body: _terms.isEmpty
          ? const Center(child: Text('No terms have been set up yet by the school.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<Term>(
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
                      _loadResults();
                    },
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _resultRows.isEmpty
                          ? const Center(child: Text('No results published for this term yet.'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                              itemCount: _resultRows.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final row = _resultRows[i];
                                final score = (row['score'] as num);
                                final max = (row['maxScore'] as num);
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _gradeColor(row['grade'] as String?),
                                    child: Text(
                                      (row['grade'] as String?) ?? '-',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(row['subject'] as String),
                                  subtitle: Text('Score: $score / $max'),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Color _gradeColor(String? grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
      case 'E':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
