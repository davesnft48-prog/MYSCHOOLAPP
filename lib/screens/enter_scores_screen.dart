import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';

class EnterScoresScreen extends StatefulWidget {
  final Term term;
  final Exam exam;
  const EnterScoresScreen({super.key, required this.term, required this.exam});

  @override
  State<EnterScoresScreen> createState() => _EnterScoresScreenState();
}

class _EnterScoresScreenState extends State<EnterScoresScreen> {
  List<Student> _students = [];
  Map<int, TextEditingController> _controllers = {};
  Map<int, double?> _existingScores = {};
  bool _loading = true;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await DBHelper.instance.getStudents(className: widget.exam.className);
    final controllers = <int, TextEditingController>{};
    final existing = <int, double?>{};

    for (final s in students) {
      final results = await DBHelper.instance.getResultsForStudent(s.id!, widget.term.id!);
      final match = results.where((r) => r.examId == widget.exam.id);
      final score = match.isNotEmpty ? match.first.score : null;
      existing[s.id!] = score;
      controllers[s.id!] = TextEditingController(text: score?.toStringAsFixed(0) ?? '');
    }

    setState(() {
      _students = students;
      _controllers = controllers;
      _existingScores = existing;
      _loading = false;
    });
  }

  Future<void> _saveScore(Student s) async {
    final text = _controllers[s.id]!.text.trim();
    if (text.isEmpty) return;
    final score = double.tryParse(text);
    if (score == null || score < 0 || score > widget.exam.maxScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a score between 0 and ${widget.exam.maxScore.toInt()}')),
      );
      return;
    }
    final result = Result(
      studentId: s.id!,
      examId: widget.exam.id!,
      score: score,
      grade: Result.gradeFor(score, widget.exam.maxScore),
      updatedAt: DateTime.now(),
    );
    await DBHelper.instance.upsertResult(result);
    await NotificationService.instance.notifyResultsPublished(
      studentName: s.fullName,
      subject: widget.exam.subject,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${s.fullName}: ${score.toInt()}')),
    );
    _load();
  }

  Future<void> _clearScore(Student s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Score?'),
        content: Text('Remove the recorded score for ${s.fullName} in ${widget.exam.subject}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.deleteResult(s.id!, widget.exam.id!);
      _controllers[s.id]!.clear();
      _load();
    }
  }

  Future<void> _saveAll() async {
    for (final s in _students) {
      final text = _controllers[s.id]!.text.trim();
      if (text.isEmpty) continue;
      final score = double.tryParse(text);
      if (score == null) continue;
      final result = Result(
        studentId: s.id!,
        examId: widget.exam.id!,
        score: score,
        grade: Result.gradeFor(score, widget.exam.maxScore),
        updatedAt: DateTime.now(),
      );
      await DBHelper.instance.upsertResult(result);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All scores saved')),
      );
    }
    _load();
  }

  /// Handles a mass-failure scenario: bump every selected (or all) student's
  /// score up or down by a flat amount, e.g. +10 curve after a hard paper.
  Future<void> _showMassAdjustDialog() async {
    final deltaCtrl = TextEditingController();
    bool applyToAll = _selected.isEmpty;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mass Adjust Scores'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(applyToAll
                  ? 'This will adjust ALL ${_students.length} students in this class.'
                  : 'This will adjust the ${_selected.length} selected student(s).'),
              const SizedBox(height: 12),
              TextField(
                controller: deltaCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Points to add (use – for subtract)',
                  hintText: 'e.g. 10 or -5',
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: applyToAll,
                title: const Text('Apply to entire class'),
                onChanged: (v) => setDialogState(() => applyToAll = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final delta = double.tryParse(deltaCtrl.text.trim());
                if (delta == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid number')),
                  );
                  return;
                }
                final ids = applyToAll
                    ? _students.map((s) => s.id!).toList()
                    : _selected.toList();
                await DBHelper.instance.bulkAdjustScores(
                  ids,
                  widget.exam.id!,
                  delta,
                  widget.exam.maxScore,
                );
                await NotificationService.instance.notifyMassUpdate(
                  className: widget.exam.className,
                  subject: widget.exam.subject,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Apply'),
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
        title: Text('${widget.exam.subject} — ${widget.exam.className}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'Mass adjust (after mass failure etc.)',
            onPressed: _students.isEmpty ? null : _showMassAdjustDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAll,
        icon: const Icon(Icons.save),
        label: const Text('Save All'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students found in this class.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = _students[i];
                    final selected = _selected.contains(s.id);
                    return ListTile(
                      leading: Checkbox(
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(s.id!);
                            } else {
                              _selected.remove(s.id);
                            }
                          });
                        },
                      ),
                      title: Text(s.fullName),
                      subtitle: Text('Adm No: ${s.admissionNo}'),
                      trailing: SizedBox(
                        width: 145,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[s.id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '/ ${widget.exam.maxScore.toInt()}',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, size: 18),
                              onPressed: () => _saveScore(s),
                            ),
                            if (_existingScores[s.id] != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _clearScore(s),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
