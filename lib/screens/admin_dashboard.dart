import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/auth_service.dart';
import 'login_screen.dart';
import 'manage_students_screen.dart';
import 'manage_terms_screen.dart';
import 'manage_exams_screen.dart';
import 'manage_teachers_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatelessWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile('Students', Icons.people_outline, 'Add & manage student records',
          (ctx) => const ManageStudentsScreen()),
      _Tile('Teachers', Icons.person_outline, 'Add & manage teacher accounts',
          (ctx) => const ManageTeachersScreen()),
      _Tile('Terms', Icons.calendar_month_outlined, 'First/Second/Third term & sessions',
          (ctx) => const ManageTermsScreen()),
      _Tile('Exams', Icons.assignment_outlined, 'Create exams per class & subject',
          (ctx) => const ManageExamsScreen()),
      _Tile('Results', Icons.grading_outlined, 'View, adjust & mass-update scores',
          (ctx) => const ManageExamsScreen()),
      _Tile('Reports', Icons.bar_chart_outlined, 'Class performance & report cards',
          (ctx) => const ReportsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name}'),
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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, i) {
          final t = tiles[i];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (t.builder == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t.title} screen — coming next')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: t.builder!),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 32, color: const Color(0xFF0B1E3D)),
                    const SizedBox(height: 10),
                    Text(t.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(t.subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tile {
  final String title;
  final IconData icon;
  final String subtitle;
  final Widget Function(BuildContext)? builder;
  _Tile(this.title, this.icon, this.subtitle, this.builder);
}
