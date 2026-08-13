// Core data models for Schoollog Exam Management App

/// Roles supported by the app
enum UserRole { admin, teacher, parent }

class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final UserRole role;
  final String? linkedStudentId; // used for parent accounts

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.linkedStudentId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.name,
        'linkedStudentId': linkedStudentId,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: map['passwordHash'] as String,
        role: UserRole.values.firstWhere((r) => r.name == map['role']),
        linkedStudentId: map['linkedStudentId'] as String?,
      );
}

class Student {
  final int? id;
  final String admissionNo;
  final String fullName;
  final String className; // e.g. "SS2 Gold"
  final String? parentEmail;

  Student({
    this.id,
    required this.admissionNo,
    required this.fullName,
    required this.className,
    this.parentEmail,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'admissionNo': admissionNo,
        'fullName': fullName,
        'className': className,
        'parentEmail': parentEmail,
      };

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        id: map['id'] as int?,
        admissionNo: map['admissionNo'] as String,
        fullName: map['fullName'] as String,
        className: map['className'] as String,
        parentEmail: map['parentEmail'] as String?,
      );
}

/// Academic term, e.g. First Term, Session 2026/2027
class Term {
  final int? id;
  final String name; // "First Term", "Second Term", "Third Term"
  final String session; // "2026/2027"
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Term({
    this.id,
    required this.name,
    required this.session,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'session': session,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': isActive ? 1 : 0,
      };

  factory Term.fromMap(Map<String, dynamic> map) => Term(
        id: map['id'] as int?,
        name: map['name'] as String,
        session: map['session'] as String,
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: DateTime.parse(map['endDate'] as String),
        isActive: (map['isActive'] as int) == 1,
      );
}

class Exam {
  final int? id;
  final String subject;
  final String className;
  final int termId;
  final double maxScore;

  Exam({
    this.id,
    required this.subject,
    required this.className,
    required this.termId,
    this.maxScore = 100,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'className': className,
        'termId': termId,
        'maxScore': maxScore,
      };

  factory Exam.fromMap(Map<String, dynamic> map) => Exam(
        id: map['id'] as int?,
        subject: map['subject'] as String,
        className: map['className'] as String,
        termId: map['termId'] as int,
        maxScore: (map['maxScore'] as num).toDouble(),
      );
}

/// A single subject score for a student within an exam
class Result {
  final int? id;
  final int studentId;
  final int examId;
  final double score;
  final String? grade; // computed: A, B, C, D, F
  final DateTime updatedAt;

  Result({
    this.id,
    required this.studentId,
    required this.examId,
    required this.score,
    this.grade,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'examId': examId,
        'score': score,
        'grade': grade,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Result.fromMap(Map<String, dynamic> map) => Result(
        id: map['id'] as int?,
        studentId: map['studentId'] as int,
        examId: map['examId'] as int,
        score: (map['score'] as num).toDouble(),
        grade: map['grade'] as String?,
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

  static String gradeFor(double score, double maxScore) {
    final pct = (score / maxScore) * 100;
    if (pct >= 75) return 'A';
    if (pct >= 65) return 'B';
    if (pct >= 55) return 'C';
    if (pct >= 45) return 'D';
    if (pct >= 40) return 'E';
    return 'F';
  }
}
