# Schoollog — Offline Exam Management App

## What's built
- Project structure (Flutter, Android + iOS)
- Data models: Users (Admin/Teacher/Parent), Students, Terms, Exams, Results
- Offline SQLite database (works with zero internet connection)
- Password-hashed authentication, role-based login → Admin / Teacher / Parent dashboards
- **Admin**: add/edit/delete students, create teacher logins, create parent logins linked
  to a student, create Terms (First/Second/Third + session dates), create Exams per class/subject
- **Teacher**: pick Term → pick Exam → enter/update scores per student, with a
  mass-adjustment tool (bulk +/- points across a class, e.g. curving after a mass failure)
- **Parent/Student**: view results by term with grades, colour-coded by grade
- **PDF report card export** — parents can download/share a full report card per term
- **Local notifications** — fired when a score is saved or a class is mass-adjusted

## Default login (seeded automatically)
- Email: `admin@schoollog.app`
- Password: `admin123`

## Typical flow to try it end-to-end
1. Log in as admin
2. Manage Terms → add "First Term", session 2026/2027, with start/end dates
3. Manage Students → add a student, including a parent email
4. Manage Exams → add a subject exam for that student's class, tied to the term
5. Manage Students → tap the key icon on that student → create a parent login
6. Manage Teachers → create a teacher login
7. Log out, log in as the teacher → Enter/Update Scores → pick the term & exam → enter a score
8. Log out, log in as the parent → View Result → see the score & grade → Download PDF

## How to run it
1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Open a terminal in this folder
3. Run:
   ```
   flutter pub get
   flutter run
   ```
   (with an emulator running, or a phone plugged in with USB debugging on)

## Possible next additions
- Search/filter across students and results
- Class performance charts (fl_chart is already in pubspec.yaml)
- Editing/removing individual exam entries
- Push-style cloud sync (currently fully offline/local by design)

