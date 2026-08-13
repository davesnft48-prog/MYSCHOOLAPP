import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import 'enter_scores_screen.dart';

class SelectExamScreen extends StatefulWidget {
  const SelectExamScreen({super.key});

  @override
  State<SelectExamScreen> createState() => _SelectExamScreenState();
}

class _SelectExamScreenState extends State<SelectExamScreen> {
  List<Term> _terms = [];
  Term? _selectedTerm;
  List<Exam> _exams = [];
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
      _loading = terms.isEmpty ? false : true;
    });
    if (_selectedTerm != null) _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _loading = true);
    final exams = await DBHelper.instance.getExams(termId: _selectedTerm!.id!);
    setState(() {
      _exams = exams;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Exam')),
      body: _terms.isEmpty
          ? const Center(child: Text('No terms have been set up yet by the admin.'))
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
                      _loadExams();
                    },
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _exams.isEmpty
                          ? const Center(child: Text('No exams for this term yet.'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _exams.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final e = _exams[i];
                                return ListTile(
                                  leading: const Icon(Icons.assignment_outlined),
                                  title: Text('${e.subject} — ${e.className}'),
                                  subtitle: Text('Max score: ${e.maxScore.toInt()}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EnterScoresScreen(
                                          term: _selectedTerm!,
                                          exam: e,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
