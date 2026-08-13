import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/auth_service.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final _auth = AuthService();
  final List<AppUser> _createdThisSession = [];

  Future<void> _showAddTeacherDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Teacher'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (login)'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
              ),
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
                final user = await _auth.createAccount(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text,
                  role: UserRole.teacher,
                );
                setState(() => _createdThisSession.add(user));
                if (ctx.mounted) Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Teachers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeacherDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
      ),
      body: _createdThisSession.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add teacher accounts here. Each teacher logs in with the email '
                  'and password you set, and can enter scores for their classes.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _createdThisSession.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = _createdThisSession[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(t.name),
                  subtitle: Text(t.email),
                );
              },
            ),
    );
  }
}
