import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:growlog/services/hive_service.dart';
import 'package:growlog/models/user_profile.dart';
import 'package:growlog/models/entry.dart';
import 'package:growlog/models/goal.dart';
import 'package:growlog/models/streak.dart';
import 'package:growlog/utils/helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Setup temporary directory for Hive in testing
    tempDir = Directory.systemTemp.createTempSync('growlog_integration_test');
    Hive.init(tempDir.path);

    // Open boxes manually as HiveService.initHive() calls Hive.initFlutter()
    await Hive.openBox(HiveService.userProfileBox);
    await Hive.openBox<List>(HiveService.entriesBox);
    await Hive.openBox<List>(HiveService.goalsBox);
    await Hive.openBox<Map>(HiveService.streaksBox);
    await Hive.openBox<List>(HiveService.badgesBox);
  });

  tearDown(() async {
    // Close Hive and delete temp files
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Integration & State Invariant Tests', () {
    test('Streak calculation, updates, resets, and same-day deduplication', () {
      final now = DateTime.now();

      // Case 1: Sequential days (Today, Yesterday, Day before yesterday)
      final dates1 = [
        now,
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 1)), // Same-day check-in
        now.subtract(const Duration(days: 2)),
      ];
      final streak1 = AppHelpers.calculateCurrentStreak(dates1);
      expect(streak1, 3); // 3 distinct days: today, yesterday, 2 days ago

      // Case 2: Broken streak (Today, Yesterday missed, Day before yesterday present)
      final dates2 = [
        now,
        now.subtract(const Duration(days: 2)),
      ];
      final streak2 = AppHelpers.calculateCurrentStreak(dates2);
      expect(streak2, 1); // Only today, yesterday was missed, so streak resets to 1

      // Case 3: Empty entries
      expect(AppHelpers.calculateCurrentStreak([]), 0);

      // Case 4: Streak model invariants
      final s = Streak(
        currentStreak: streak1,
        longestStreak: 2,
        lastEntryDate: now,
      );
      // longestStreak must be >= currentStreak
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 3);
    });

    test('Goal completion flow status and completedAt pairing', () async {
      // 1. Create a goal with 'active' status
      final goal = Goal(
        id: 'g-test-1',
        text: 'Master Flutter Integration Testing',
        linkedTo: 'Programming',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'active',
      );
      expect(goal.status, 'active');
      expect(goal.completedAt, isNull);

      // 2. Mock saving/retrieving via HiveService
      await HiveService.addGoal(goal);
      final retrieved = HiveService.getAllGoals().first;
      expect(retrieved.status, 'active');
      expect(retrieved.completedAt, isNull);

      // 3. Mark completed
      final completedGoal = retrieved.copyWith(
        status: 'done',
        completedAt: DateTime.now(),
      );
      await HiveService.updateGoal(completedGoal);

      final retrievedCompleted = HiveService.getAllGoals().first;
      expect(retrievedCompleted.status, 'done');
      expect(retrievedCompleted.completedAt, isNotNull);
    });

    test('Multi-profile partitioning and profile switching/deletion', () async {
      // 1. Create Profile A
      final profileA = UserProfile(
        name: 'User A',
        username: 'usera',
        email: 'usera@gmail.com',
        mode: 'student',
        roleOrClass: 'Class 10',
        skillsOrSubjects: ['Math'],
        reminderTime: '08:00',
        isFirstTime: false,
      );

      // 2. Create Profile B
      final profileB = UserProfile(
        name: 'User B',
        username: 'userb',
        email: 'userb@gmail.com',
        mode: 'professional',
        roleOrClass: 'Engineer',
        skillsOrSubjects: ['Coding'],
        reminderTime: '09:00',
        isFirstTime: false,
      );

      // Save both profiles
      await HiveService.saveUserProfile(profileA);
      await HiveService.saveUserProfile(profileB);

      // Verify profiles list has both emails
      expect(HiveService.getAllProfiles().length, 2);

      // Switch to Profile A, add an entry
      await HiveService.switchProfile(profileA.email);
      final entryA = Entry(
        date: DateTime.now(),
        mode: 'student',
        learned: 'Algebra',
        subjectOrSkill: 'Math',
        hoursOrEnergy: 1.5,
        moodOrFocus: '5',
        win: 'Solved 10 equations',
        improve: 'Speed',
      );
      await HiveService.addEntry(entryA);

      // Switch to Profile B, add an entry
      await HiveService.switchProfile(profileB.email);
      final entryB = Entry(
        date: DateTime.now(),
        mode: 'professional',
        learned: 'Writing tests',
        subjectOrSkill: 'Coding',
        hoursOrEnergy: 2.0,
        moodOrFocus: 'focused',
        win: 'Tests passed',
        improve: 'Coverage',
      );
      await HiveService.addEntry(entryB);

      // Check partition separation
      // Profile B should only see entryB
      final entriesB = HiveService.getAllEntries();
      expect(entriesB.length, 1);
      expect(entriesB.first.learned, 'Writing tests');

      // Switch back to Profile A and verify its entries
      await HiveService.switchProfile(profileA.email);
      final entriesA = HiveService.getAllEntries();
      expect(entriesA.length, 1);
      expect(entriesA.first.learned, 'Algebra');

      // Delete Profile A and check cleanup
      await HiveService.deleteProfile(profileA.email);
      expect(HiveService.getAllProfiles().length, 1);
      expect(HiveService.getActiveUserEmail(), profileB.email); // Auto switched to remaining profile
      
      // Profile A's entries should be gone
      final boxEntries = Hive.box<List>(HiveService.entriesBox);
      expect(boxEntries.get('entries_${profileA.email}'), isNull);
    });

    test('Historic entries retain references to completed/dropped topics', () async {
      // 1. Create a user profile with 'Math' and 'Physics'
      final profile = UserProfile(
        name: 'Alex',
        username: 'alex',
        email: 'alex@gmail.com',
        mode: 'student',
        roleOrClass: 'Grade 12',
        skillsOrSubjects: ['Math', 'Physics'],
        reminderTime: '10:00',
        isFirstTime: false,
      );
      await HiveService.saveUserProfile(profile);

      // 2. Create an entry linked to 'Math'
      final entry = Entry(
        date: DateTime.now().subtract(const Duration(days: 5)),
        mode: 'student',
        learned: 'Calculus limits',
        subjectOrSkill: 'Math',
        hoursOrEnergy: 2.0,
        moodOrFocus: '4',
        win: 'Understood limits',
        improve: 'Nothing',
      );
      await HiveService.addEntry(entry);

      // 3. Drop 'Math' topic (modify profile skills to only contain 'Physics' and 'Chemistry')
      final updatedProfile = profile.copyWith(
        skillsOrSubjects: ['Physics', 'Chemistry'],
      );
      await HiveService.saveUserProfile(updatedProfile);

      // 4. Retrieve historic entries and verify the dropped topic ('Math') is still retained
      final entries = HiveService.getAllEntries();
      expect(entries.length, 1);
      expect(entries.first.subjectOrSkill, 'Math'); // Math remains intact in historic entry
    });
  });
}
