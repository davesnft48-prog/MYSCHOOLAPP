import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../database/db_helper.dart';

class ManageTermsScreen extends StatefulWidget {
  const ManageTermsScreen({super.key});

  @override
  State<ManageTermsScreen> createState() => _ManageTermsScreenState();
}

class _ManageTermsScreenState extends State<ManageTermsScreen> {
  List<Term> _terms = [];
  bool _loading = true;
  final _dateFmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await DBHelper.instance.getTerms();
    setState(() {
      _terms = list;
      _loading = false;
    });
  }

  Future<void> _showAddTermDialog() async {
    String? selectedTermName = 'First Term';
    final sessionCtrl = TextEditingController(text: '2026/2027');
    DateTime? startDate;
    DateTime? endDate;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Term'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTermName,
                    decoration: const InputDecoration(labelText: 'Term'),
                    items: const [
                      DropdownMenuItem(value: 'First Term', child: Text('First Term')),
                      DropdownMenuItem(value: 'Second Term', child: Text('Second Term')),
                      DropdownMenuItem(value: 'Third Term', child: Text('Third Term')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedTermName = v),
                  ),
                  TextFormField(
                    controller: sessionCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Session (e.g. 2026/2027)'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(startDate == null
                        ? 'Select start date'
                        : 'Start: ${_dateFmt.format(startDate!)}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime(2026, 9, 1),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setDialogState(() => startDate = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(endDate == null
                        ? 'Select end date'
                        : 'End: ${_dateFmt.format(endDate!)}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime(2026, 12, 1),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setDialogState(() => endDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please pick both start and end dates')),
                  );
                  return;
                }
                final term = Term(
                  name: selectedTermName!,
                  session: sessionCtrl.text.trim(),
                  startDate: startDate!,
                  endDate: endDate!,
                );
                await DBHelper.instance.insertTerm(term);
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Terms')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTermDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Term'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _terms.isEmpty
              ? const Center(
                  child: Text('No terms yet. Tap "Add Term" to create First Term, etc.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _terms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = _terms[i];
                    return ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text('${t.name} — ${t.session}'),
                      subtitle: Text(
                          '${_dateFmt.format(t.startDate)}  →  ${_dateFmt.format(t.endDate)}'),
                    );
                  },
                ),
    );
  }
}
