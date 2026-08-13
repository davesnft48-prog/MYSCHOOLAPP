import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/auth_service.dart';
import 'login_screen.dart';
import 'view_result_screen.dart';

class ParentPortal extends StatelessWidget {
  final AppUser user;
  const ParentPortal({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent: ${user.name}'),
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
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('View Result'),
            subtitle: const Text('Select a term to see your child\'s scores and grades'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewResultScreen(parentUser: user)),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Download Report Card (PDF)'),
            subtitle: const Text('No need to visit the school'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewResultScreen(parentUser: user)),
              );
            },
          ),
        ],
      ),
    );
  }
}
