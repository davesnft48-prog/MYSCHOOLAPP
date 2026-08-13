import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'db_helper.dart';

/// Handles login, signup (admin-created accounts), and session state.
/// Works fully offline — credentials are checked against the local DB.
class AuthService {
  static const _sessionEmailKey = 'session_email';

  static String hashPassword(String plain) {
    return sha256.convert(utf8.encode(plain)).toString();
  }

  /// Returns the logged-in user, or null if credentials are invalid.
  Future<AppUser?> login(String email, String password) async {
    final user = await DBHelper.instance.getUserByEmail(email.trim().toLowerCase());
    if (user == null) return null;
    if (user.passwordHash != hashPassword(password)) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionEmailKey, user.email);
    return user;
  }

  /// Admin-only: create a Teacher or Parent account.
  Future<AppUser> createAccount({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? linkedStudentId,
  }) async {
    final user = AppUser(
      name: name,
      email: email.trim().toLowerCase(),
      passwordHash: hashPassword(password),
      role: role,
      linkedStudentId: linkedStudentId,
    );
    final id = await DBHelper.instance.insertUser(user);
    return AppUser(
      id: id,
      name: user.name,
      email: user.email,
      passwordHash: user.passwordHash,
      role: user.role,
      linkedStudentId: user.linkedStudentId,
    );
  }

  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionEmailKey);
    if (email == null) return null;
    return DBHelper.instance.getUserByEmail(email);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
  }
}
