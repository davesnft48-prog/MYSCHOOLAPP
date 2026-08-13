import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

/// Offline-first local database. All data lives on-device (sqflite),
/// so the app works fully without internet access.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'schoollog.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        role TEXT NOT NULL,
        linkedStudentId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admissionNo TEXT NOT NULL UNIQUE,
        fullName TEXT NOT NULL,
        className TEXT NOT NULL,
        parentEmail TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE terms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        session TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        className TEXT NOT NULL,
        termId INTEGER NOT NULL,
        maxScore REAL NOT NULL DEFAULT 100,
        FOREIGN KEY (termId) REFERENCES terms (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        examId INTEGER NOT NULL,
        score REAL NOT NULL,
        grade TEXT,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (studentId) REFERENCES students (id),
        FOREIGN KEY (examId) REFERENCES exams (id)
      )
    ''');

    // Seed a default admin account: admin@schoollog.app / admin123
    // (This is sha256("admin123") — matches AuthService.hashPassword)
    await db.insert('users', {
      'name': 'School Admin',
      'email': 'admin@schoollog.app',
      'passwordHash': '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a',
      'role': 'admin',
      'linkedStudentId': null,
    });
  }

  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final rows = await db.query('students', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Student.fromMap(rows.first);
  }

  /// Returns result rows joined with exam subject/maxScore, for a student+term.
  Future<List<Map<String, dynamic>>> getResultDetailsForStudent(
      int studentId, int termId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT results.score, results.grade, results.updatedAt,
             exams.subject, exams.maxScore
      FROM results
      INNER JOIN exams ON results.examId = exams.id
      WHERE results.studentId = ? AND exams.termId = ?
      ORDER BY exams.subject
    ''', [studentId, termId]);
  }

  /// Average score and grade distribution for a given exam (class performance)
  Future<Map<String, dynamic>> getExamPerformance(int examId) async {
    final db = await database;
    final rows = await db.query('results', where: 'examId = ?', whereArgs: [examId]);
    if (rows.isEmpty) {
      return {'average': 0.0, 'gradeDistribution': <String, int>{}, 'count': 0};
    }
    double total = 0;
    final dist = <String, int>{'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0};
    for (final r in rows) {
      total += (r['score'] as num).toDouble();
      final g = r['grade'] as String?;
      if (g != null && dist.containsKey(g)) dist[g] = dist[g]! + 1;
    }
    return {
      'average': total / rows.length,
      'gradeDistribution': dist,
      'count': rows.length,
    };
  }

  // ---------- USERS ----------
  Future<int> insertUser(AppUser user) async {
    final db = await database;
    return db.insert('users', user.toMap()..remove('id'));
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  // ---------- STUDENTS ----------
  Future<int> insertStudent(Student s) async {
    final db = await database;
    return db.insert('students', s.toMap()..remove('id'));
  }

  Future<List<Student>> getStudents({String? className}) async {
    final db = await database;
    final rows = className == null
        ? await db.query('students', orderBy: 'fullName')
        : await db.query('students',
            where: 'className = ?', whereArgs: [className], orderBy: 'fullName');
    return rows.map((r) => Student.fromMap(r)).toList();
  }

  Future<int> updateStudent(Student s) async {
    final db = await database;
    return db.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- TERMS ----------
  Future<int> insertTerm(Term t) async {
    final db = await database;
    return db.insert('terms', t.toMap()..remove('id'));
  }

  Future<List<Term>> getTerms() async {
    final db = await database;
    final rows = await db.query('terms', orderBy: 'startDate DESC');
    return rows.map((r) => Term.fromMap(r)).toList();
  }

  // ---------- EXAMS ----------
  Future<int> insertExam(Exam e) async {
    final db = await database;
    return db.insert('exams', e.toMap()..remove('id'));
  }

  Future<List<Exam>> getExams({required int termId, String? className}) async {
    final db = await database;
    final rows = className == null
        ? await db.query('exams', where: 'termId = ?', whereArgs: [termId])
        : await db.query('exams',
            where: 'termId = ? AND className = ?', whereArgs: [termId, className]);
    return rows.map((r) => Exam.fromMap(r)).toList();
  }

  // ---------- RESULTS ----------
  /// Insert or update a score (upsert on studentId+examId)
  Future<void> upsertResult(Result r) async {
    final db = await database;
    final existing = await db.query('results',
        where: 'studentId = ? AND examId = ?', whereArgs: [r.studentId, r.examId]);
    if (existing.isEmpty) {
      await db.insert('results', r.toMap()..remove('id'));
    } else {
      await db.update('results', r.toMap(), where: 'id = ?', whereArgs: [existing.first['id']]);
    }
  }

  /// Bulk update, e.g. mass-adjust scores after a mass-failure review
  Future<void> bulkAdjustScores(List<int> studentIds, int examId, double delta, double maxScore) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final sid in studentIds) {
        final rows = await txn.query('results',
            where: 'studentId = ? AND examId = ?', whereArgs: [sid, examId]);
        if (rows.isNotEmpty) {
          final current = (rows.first['score'] as num).toDouble();
          var newScore = current + delta;
          if (newScore < 0) newScore = 0;
          if (newScore > maxScore) newScore = maxScore;
          await txn.update(
            'results',
            {
              'score': newScore,
              'grade': Result.gradeFor(newScore, maxScore),
              'updatedAt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [rows.first['id']],
          );
        }
      }
    });
  }

  /// Remove a single result entry (e.g. entered in error)
  Future<int> deleteResult(int studentId, int examId) async {
    final db = await database;
    return db.delete('results', where: 'studentId = ? AND examId = ?', whereArgs: [studentId, examId]);
  }

  Future<List<Result>> getResultsForStudent(int studentId, int termId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT results.* FROM results
      INNER JOIN exams ON results.examId = exams.id
      WHERE results.studentId = ? AND exams.termId = ?
    ''', [studentId, termId]);
    return rows.map((r) => Result.fromMap(r)).toList();
  }
}
