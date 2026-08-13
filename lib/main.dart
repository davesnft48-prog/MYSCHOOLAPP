import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SchoollogApp());
}

class SchoollogApp extends StatelessWidget {
  const SchoollogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schoollog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0B1E3D),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B1E3D)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
