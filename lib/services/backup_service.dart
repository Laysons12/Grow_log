import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'hive_service.dart';
import '../models/user_profile.dart';
import '../models/entry.dart';
import '../models/goal.dart';
import '../models/streak.dart';

class BackupService {
  // Simulate Cloud DB using local persistent files
  static Future<File> _getBackupFile(String email) async {
    String cleanEmail = email.replaceAll(RegExp(r'[^\w\.-]'), '_');
    
    if (!kIsWeb && Platform.isWindows) {
      // On Windows, save to the user's home directory so it persists app deletions
      final homeDir = Platform.environment['USERPROFILE'] ?? '.';
      return File('$homeDir/growlog_backup_$cleanEmail.json');
    } else {
      // On mobile/other platforms, save to public Downloads or AppDocuments as fallback
      try {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          return File('${dir.path}/growlog_backup_$cleanEmail.json');
        }
      } catch (_) {}
      
      final docsDir = await getApplicationDocumentsDirectory();
      return File('${docsDir.path}/growlog_backup_$cleanEmail.json');
    }
  }

  // Check if a backup exists for this email
  static Future<bool> hasBackup(String email) async {
    if (email.trim().isEmpty) return false;
    
    // For demo/testing, simulate that "demo@growlog.com" or "test@gmail.com" always has a backup
    if (email == 'demo@growlog.com' || email == 'test@gmail.com') {
      return true;
    }

    try {
      final file = await _getBackupFile(email);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  // Backup all data to "cloud" (JSON file)
  static Future<void> createBackup() async {
    final profile = HiveService.getUserProfile();
    if (profile == null || profile.email.isEmpty) return;

    try {
      final data = {
        'profile': profile.toMap(),
        'entries': HiveService.getAllEntries().map((e) => e.toMap()).toList(),
        'goals': HiveService.getAllGoals().map((g) => g.toMap()).toList(),
        'streak': HiveService.getStreak()?.toMap(),
        'badges': HiveService.getBadges(),
      };

      final file = await _getBackupFile(profile.email);
      await file.writeAsString(jsonEncode(data));
      debugPrint('Backup saved to ${file.path}');
    } catch (e) {
      debugPrint('Error creating backup: $e');
    }
  }

  // Restore all data from backup
  static Future<bool> restoreBackup(String email) async {
    try {
      Map<String, dynamic>? data;

      // Handle demo accounts with pre-loaded mock data
      if ((email == 'demo@growlog.com' || email == 'test@gmail.com') && 
          !(await (await _getBackupFile(email)).exists())) {
        data = _getMockBackupData(email);
      } else {
        final file = await _getBackupFile(email);
        if (await file.exists()) {
          final content = await file.readAsString();
          data = jsonDecode(content) as Map<String, dynamic>;
        }
      }

      if (data == null) return false;

      // Validate all imported data BEFORE writing to database
      try {
        if (data['profile'] != null) {
          UserProfile.fromMap(Map<String, dynamic>.from(data['profile']));
        }
        if (data['streak'] != null) {
          Streak.fromMap(Map<String, dynamic>.from(data['streak']));
        }
        if (data['entries'] != null) {
          for (var e in data['entries'] as List) {
            Entry.fromMap(Map<String, dynamic>.from(e));
          }
        }
        if (data['goals'] != null) {
          for (var g in data['goals'] as List) {
            Goal.fromMap(Map<String, dynamic>.from(g));
          }
        }
      } catch (validationError) {
        debugPrint('Backup data validation failed: $validationError');
        return false;
      }

      // Clear existing local data
      await HiveService.clearAllData();

      // Restore User Profile
      if (data['profile'] != null) {
        final profile = UserProfile.fromMap(Map<String, dynamic>.from(data['profile']));
        await HiveService.saveUserProfile(profile);
      }

      // Restore Streak
      if (data['streak'] != null) {
        final streak = Streak.fromMap(Map<String, dynamic>.from(data['streak']));
        await HiveService.saveStreak(streak);
      }

      // Restore Entries
      if (data['entries'] != null) {
        final entriesList = data['entries'] as List;
        for (var e in entriesList) {
          final entry = Entry.fromMap(Map<String, dynamic>.from(e));
          await HiveService.addEntry(entry);
        }
      }

      // Restore Goals
      if (data['goals'] != null) {
        final goalsList = data['goals'] as List;
        for (var g in goalsList) {
          final goal = Goal.fromMap(Map<String, dynamic>.from(g));
          await HiveService.addGoal(goal);
        }
      }

      // Restore Badges
      if (data['badges'] != null) {
        final badgesList = data['badges'] as List;
        for (var b in badgesList) {
          await HiveService.addBadge(b.toString());
        }
      }

      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  // Mock data for demo restore
  static Map<String, dynamic> _getMockBackupData(String email) {
    final now = DateTime.now();
    return {
      'profile': {
        'name': 'Alex Mercer',
        'username': 'alex',
        'email': email,
        'mode': 'professional',
        'roleOrClass': 'Lead Developer',
        'skillsOrSubjects': ['Programming', 'UI/UX Design', 'Project Management'],
        'reminderTime': '20:00',
        'isFirstTime': false,
        'createdAt': now.subtract(const Duration(days: 45)).toIso8601String(),
      },
      'streak': {
        'currentStreak': 5,
        'longestStreak': 18,
        'lastEntryDate': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      'badges': ['7_day_streak', 'first_goal'],
      'entries': [
        {
          'id': '1',
          'date': now.subtract(const Duration(days: 1)).toIso8601String(),
          'mode': 'professional',
          'learned': 'Implemented clean architecture and added repository pattern unit tests.',
          'subjectOrSkill': 'Programming',
          'hoursOrEnergy': 4.5,
          'moodOrFocus': 'focused',
          'win': 'Finished the core data layer ahead of schedule',
          'improve': 'Need to start task breakdown earlier in the day',
        },
        {
          'id': '2',
          'date': now.subtract(const Duration(days: 2)).toIso8601String(),
          'mode': 'professional',
          'learned': 'Designed and refined the user onboarding flows and bottom navigation interactions.',
          'subjectOrSkill': 'UI/UX Design',
          'hoursOrEnergy': 3.0,
          'moodOrFocus': 'motivated',
          'win': 'Designed fully responsive views for mobile and desktop screens',
          'improve': 'Incorporate client feedback faster next time',
        },
        {
          'id': '3',
          'date': now.subtract(const Duration(days: 3)).toIso8601String(),
          'mode': 'professional',
          'learned': 'Conducted weekly planning, created sprint backlog, and assigned milestones.',
          'subjectOrSkill': 'Project Management',
          'hoursOrEnergy': 2.0,
          'moodOrFocus': 'calm',
          'win': 'Aligned development team on the upcoming deliverables',
          'improve': 'Spend less time in meetings, focus on deep work',
        }
      ],
      'goals': [
        {
          'id': 'g1',
          'text': 'Complete Advanced UI course',
          'linkedTo': 'UI/UX Design',
          'dueDate': now.add(const Duration(days: 10)).toIso8601String(),
          'status': 'active',
        },
        {
          'id': 'g2',
          'text': 'Learn Unit Testing in Flutter',
          'linkedTo': 'Programming',
          'dueDate': now.subtract(const Duration(days: 2)).toIso8601String(),
          'status': 'done',
          'completedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        }
      ]
    };
  }
}
