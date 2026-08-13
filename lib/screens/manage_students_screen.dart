import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/db_helper.dart';
import '../database/auth_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<Student> _students = [];
  List<Student> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
    _searchCtrl.addListener(_applyFilter);
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _students
          : _students
              .where((s) =>
                  s.fullName.toLowerCase().contains(q) ||
                  s.admissionNo.toLowerCase().contains(q) ||
                  s.className.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await DBHelper.instance.getStudents();
    setState(() {
      _students = list;
      _loading = false;
    });
    _applyFilter();
  }

  Future<void> _showAddEditDialog({Student? existing}) async {
    final admissionCtrl = TextEditingController(text: existing?.admissionNo ?? '');
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final classCtrl = TextEditingController(text: existing?.className ?? '');
    final parentEmailCtrl = TextEditingController(text: existing?.parentEmail ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Student' : 'Edit Student'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: admissionCtrl,
                  decoration: const InputDecoration(labelText: 'Admission No.'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: classCtrl,
                  decoration: const InputDecoration(labelText: 'Class (e.g. SS2 Gold)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: parentEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Parent Email (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final student = Student(
                id: existing?.id,
                admissionNo: admissionCtrl.text.trim(),
                fullName: nameCtrl.text.trim(),
                className: classCtrl.text.trim(),
                parentEmail: parentEmailCtrl.text.trim().isEmpty
                    ? null
                    : parentEmailCtrl.text.trim(),
              );
              if (existing == null) {
                await DBHelper.instance.insertStudent(student);
              } else {
                await DBHelper.instance.updateStudent(student);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _createParentLogin(Student s) async {
    if (s.parentEmail == null || s.parentEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a parent email for this student first (edit student).')),
      );
      return;
    }
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Parent Login\nfor ${s.fullName}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Login email: ${s.parentEmail}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Temporary Password'),
                validator: (v) => (v == null || v.length < 4) ? 'Min 4 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await AuthService().createAccount(
                  name: '${s.fullName} (Parent)',
                  email: s.parentEmail!,
                  password: passwordCtrl.text,
                  role: UserRole.parent,
                  linkedStudentId: s.id.toString(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Parent login created')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('That email is already registered.')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Student s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Remove ${s.fullName} (${s.admissionNo})? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && s.id != null) {
      await DBHelper.instance.deleteStudent(s.id!);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Students')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, admission no, or class',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchCtrl.clear(),
                      ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(_students.isEmpty
                            ? 'No students yet. Tap "Add Student" to begin.'
                            : 'No students match your search.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = _filtered[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(s.fullName.isNotEmpty ? s.fullName[0] : '?'),
                            ),
                            title: Text(s.fullName),
                            subtitle: Text('${s.className} • Adm No: ${s.admissionNo}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.key_outlined),
                                  tooltip: 'Create parent login',
                                  onPressed: () => _createParentLogin(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showAddEditDialog(existing: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _confirmDelete(s),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
