import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/models/user_profile.dart';
import 'package:growlog/models/entry.dart';
import 'package:growlog/models/goal.dart';
import 'package:growlog/models/streak.dart';

void main() {
  group('Model Invariant Tests', () {
    test('Streak longestStreak invariant', () {
      final s1 = Streak(currentStreak: 5, longestStreak: 10, lastEntryDate: DateTime.now());
      expect(s1.currentStreak, 5);
      expect(s1.longestStreak, 10);

      final s2 = Streak(currentStreak: 12, longestStreak: 10, lastEntryDate: DateTime.now());
      expect(s2.currentStreak, 12);
      expect(s2.longestStreak, 12); // auto-increased to match current

      final s3 = Streak(currentStreak: -2, longestStreak: 5, lastEntryDate: DateTime.now());
      expect(s3.currentStreak, 0); // clamped to 0
      expect(s3.longestStreak, 5);
    });

    test('Goal status and completedAt pairing', () {
      final g1 = Goal(
        text: 'Learn Dart',
        linkedTo: 'Programming',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: 'active',
        completedAt: DateTime.now(),
      );
      expect(g1.status, 'active');
      expect(g1.completedAt, isNull); // active goals must have null completedAt

      final g2 = Goal(
        text: 'Learn Dart',
        linkedTo: 'Programming',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: 'done',
        completedAt: null,
      );
      expect(g2.status, 'done');
      expect(g2.completedAt, isNotNull); // done goals must have completedAt set

      // Legacy statuses normalization
      final g3 = Goal(
        text: 'Learn Dart',
        linkedTo: 'Programming',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: 'not_started',
      );
      expect(g3.status, 'active');
    });

    test('UserProfile validations and immutability', () {
      // Valid creation
      final profile = UserProfile(
        name: 'John Doe',
        username: 'john1',
        email: 'john@doe.com',
        mode: 'student',
        roleOrClass: 'Class 10',
        skillsOrSubjects: ['Mathematics'],
        reminderTime: '09:00',
        isFirstTime: false,
      );
      expect(profile.name, 'John Doe');

      // Invalid name creation throws ArgumentError
      expect(() => UserProfile(
        name: 'John123',
        username: 'john1',
        email: 'john@doe.com',
        mode: 'student',
        roleOrClass: 'Class 10',
        skillsOrSubjects: ['Mathematics'],
        reminderTime: '09:00',
        isFirstTime: false,
      ), throwsArgumentError);

      // copyWith immutability checks
      expect(() => profile.copyWith(email: 'newemail@domain.com'), throwsArgumentError);
      expect(() => profile.copyWith(username: 'newusername'), throwsArgumentError);
      expect(() => profile.copyWith(createdAt: DateTime.now().add(const Duration(days: 1))), throwsArgumentError);
    });

    test('Entry validations and hours rounding', () {
      final entry = Entry(
        date: DateTime.now(),
        mode: 'student',
        learned: 'Flutter layout widgets',
        subjectOrSkill: 'Mathematics',
        hoursOrEnergy: 2.1264,
        moodOrFocus: '4',
        win: 'Built a screen',
        improve: 'Code speed',
      );
      expect(entry.hoursOrEnergy, 2.13); // rounded to 2 decimal places

      // Future date throws error
      expect(() => Entry(
        date: DateTime.now().add(const Duration(days: 1)),
        mode: 'student',
        learned: 'Flutter',
        subjectOrSkill: 'Mathematics',
        hoursOrEnergy: 2.0,
        moodOrFocus: '4',
        win: 'Win',
        improve: 'Improve',
      ), throwsArgumentError);

      // Hours > 16 throws error
      expect(() => Entry(
        date: DateTime.now(),
        mode: 'student',
        learned: 'Flutter',
        subjectOrSkill: 'Mathematics',
        hoursOrEnergy: 18.0,
        moodOrFocus: '4',
        win: 'Win',
        improve: 'Improve',
      ), throwsArgumentError);
    });
  });
}
