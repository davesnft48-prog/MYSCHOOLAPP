import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/db_helper.dart';

class ManageExamsScreen extends StatefulWidget {
  const ManageExamsScreen({super.key});

  @override
  State<ManageExamsScreen> createState() => _ManageExamsScreenState();
}

class _ManageExamsScreenState extends State<ManageExamsScreen> {
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
    });
    if (_selectedTerm != null) _loadExams();
  }

  Future<void> _loadExams() async {
    if (_selectedTerm?.id == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final exams = await DBHelper.instance.getExams(termId: _selectedTerm!.id!);
    setState(() {
      _exams = exams;
      _loading = false;
    });
  }

  Future<void> _showAddExamDialog() async {
    if (_selectedTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a Term first before adding exams')),
      );
      return;
    }
    final subjectCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final maxScoreCtrl = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Exam — ${_selectedTerm!.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: 'Class (e.g. SS2 Gold)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: maxScoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Score'),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a number' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final exam = Exam(
                subject: subjectCtrl.text.trim(),
                className: classCtrl.text.trim(),
                termId: _selectedTerm!.id!,
                maxScore: double.parse(maxScoreCtrl.text.trim()),
              );
              await DBHelper.instance.insertExam(exam);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadExams();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Exams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExamDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Exam'),
      ),
      body: Column(
        children: [
          if (_terms.isNotEmpty)
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
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No terms yet — create a Term first from the dashboard.'),
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
