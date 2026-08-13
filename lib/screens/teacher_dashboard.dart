import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/auth_service.dart';
import 'login_screen.dart';
import 'select_exam_screen.dart';

class TeacherDashboard extends StatelessWidget {
  final AppUser user;
  const TeacherDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher: ${user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Enter / Update Scores'),
            subtitle: const Text('Input results for your subjects, supports mass adjustment'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectExamScreen()),
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.assignment_turned_in_outlined),
            title: Text('My Classes'),
            subtitle: Text('View students assigned to your subjects'),
          ),
        ],
      ),
    );
  }
}
