import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/entry.dart';
import '../models/goal.dart';
import '../models/streak.dart';
import 'backup_service.dart';

class HiveService {
  static const String userProfileBox = 'user_profile';
  static const String entriesBox = 'entries';
  static const String goalsBox = 'goals';
  static const String streaksBox = 'streaks';
  static const String badgesBox = 'badges';

  static const String activeUserEmailKey = 'active_user_email';
  static const String profilesListKey = 'profiles_list';
  static const String darkModeKey = 'dark_mode';
  static const String onboardingSeenKey = 'onboarding_seen';

  // Initialize Hive
  static Future<void> initHive() async {
    await Hive.initFlutter();

    // Open all boxes
    await Hive.openBox(userProfileBox);
    await Hive.openBox<List>(entriesBox);
    await Hive.openBox<List>(goalsBox);
    await Hive.openBox<Map>(streaksBox);
    await Hive.openBox<List>(badgesBox);
  }

  // THEME MANAGEMENT
  static bool isDarkMode() {
    final box = Hive.box(userProfileBox);
    return box.get(darkModeKey) as bool? ?? true;
  }

  static Future<void> setDarkMode(bool isDark) async {
    final box = Hive.box(userProfileBox);
    await box.put(darkModeKey, isDark);
  }

  // ONBOARDING SLIDESHOW
  static bool hasSeenOnboarding() {
    final box = Hive.box(userProfileBox);
    return box.get(onboardingSeenKey) as bool? ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final box = Hive.box(userProfileBox);
    await box.put(onboardingSeenKey, true);
  }

  // USERNAME / EMAIL UNIQUENESS CHECKS
  static bool isUsernameTaken(String username, {String? excludeEmail}) {
    final box = Hive.box(userProfileBox);
    final List profilesList = box.get(profilesListKey) as List? ?? [];
    for (final email in profilesList) {
      if (excludeEmail != null && email == excludeEmail) continue;
      final data = box.get('profile_$email');
      if (data != null) {
        final profile = UserProfile.fromMap(Map<String, dynamic>.from(data as Map));
        if (profile.username.toLowerCase() == username.toLowerCase()) {
          return true;
        }
      }
    }
    return false;
  }

  static bool isEmailTaken(String email) {
    final box = Hive.box(userProfileBox);
    final List profilesList = box.get(profilesListKey) as List? ?? [];
    return profilesList.contains(email);
  }

  // ACTIVE USER MANAGEMENT
  static String? getActiveUserEmail() {
    final box = Hive.box(userProfileBox);
    return box.get(activeUserEmailKey) as String?;
  }

  static bool hasUser() {
    return getActiveUserEmail() != null;
  }

  // PROFILE MANAGEMENT (Multi-profile)
  static Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box(userProfileBox);
    
    // Save profile under profile_email key
    await box.put('profile_${profile.email}', profile.toMap());
    
    // Set as active user
    await box.put(activeUserEmailKey, profile.email);

    // Add to list of registered profiles
    final List profiles = (box.get(profilesListKey) as List?)?.toList() ?? [];
    if (!profiles.contains(profile.email)) {
      profiles.add(profile.email);
      await box.put(profilesListKey, profiles);
    }

    await BackupService.createBackup();
  }

  static UserProfile? getUserProfile() {
    final activeEmail = getActiveUserEmail();
    if (activeEmail == null) return null;

    final box = Hive.box(userProfileBox);
    final data = box.get('profile_$activeEmail');
    if (data == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(data as Map));
  }

  static List<UserProfile> getAllProfiles() {
    final box = Hive.box(userProfileBox);
    final List profilesList = box.get(profilesListKey) as List? ?? [];
    
    return profilesList.map((email) {
      final data = box.get('profile_$email');
      if (data == null) return null;
      return UserProfile.fromMap(Map<String, dynamic>.from(data as Map));
    }).whereType<UserProfile>().toList();
  }

  static Future<void> switchProfile(String email) async {
    final box = Hive.box(userProfileBox);
    await box.put(activeUserEmailKey, email);
  }

  static Future<void> deleteProfile(String email) async {
    final box = Hive.box(userProfileBox);
    
    // Remove from profiles list
    final List profilesList = (box.get(profilesListKey) as List?)?.toList() ?? [];
    profilesList.remove(email);
    await box.put(profilesListKey, profilesList);

    // Delete profile data
    await box.delete('profile_$email');

    // Clean up partitioned boxes
    final entriesB = Hive.box<List>(entriesBox);
    await entriesB.delete('entries_$email');

    final goalsB = Hive.box<List>(goalsBox);
    await goalsB.delete('goals_$email');

    final streaksB = Hive.box<Map>(streaksBox);
    await streaksB.delete('streak_$email');

    final badgesB = Hive.box<List>(badgesBox);
    await badgesB.delete('badges_$email');

    // If deleted active user, set active to another or null
    final activeEmail = getActiveUserEmail();
    if (activeEmail == email) {
      if (profilesList.isNotEmpty) {
        await box.put(activeUserEmailKey, profilesList.first);
      } else {
        await box.delete(activeUserEmailKey);
      }
    }
  }

  // ENTRIES (Partitioned by active profile)
  static Future<void> addEntry(Entry entry) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(entriesBox);
    List entries = box.get('entries_$email') ?? [];
    entries.add(entry.toMap());
    await box.put('entries_$email', entries);
    await BackupService.createBackup();
  }

  static Future<void> updateEntry(Entry entry) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(entriesBox);
    List entries = box.get('entries_$email') ?? [];
    final index = entries.indexWhere((e) => e['id'] == entry.id);
    if (index != -1) {
      entries[index] = entry.toMap();
      await box.put('entries_$email', entries);
      await BackupService.createBackup();
    }
  }

  static Future<void> deleteEntry(String entryId) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(entriesBox);
    List entries = box.get('entries_$email') ?? [];
    entries.removeWhere((e) => e['id'] == entryId);
    await box.put('entries_$email', entries);
    await BackupService.createBackup();
  }

  static List<Entry> getAllEntries() {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(entriesBox);
    final entries = box.get('entries_$email') ?? [];
    return entries
        .map((e) => Entry.fromMap(e.cast<String, dynamic>()))
        .toList();
  }

  static List<Entry> getEntriesByDate(DateTime date) {
    final allEntries = getAllEntries();
    return allEntries
        .where(
          (e) =>
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day,
        )
        .toList();
  }

  static Entry? getTodayEntry() {
    final today = DateTime.now();
    final entries = getEntriesByDate(today);
    return entries.isNotEmpty ? entries.last : null;
  }

  static List<Entry> getEntriesLastNDays(int days) {
    final allEntries = getAllEntries();
    final startDate = DateTime.now().subtract(Duration(days: days));
    return allEntries.where((e) => e.date.isAfter(startDate)).toList();
  }

  /// Returns the existing entry for a specific subject on today's date, or null.
  static Entry? getTodayEntryForSubject(String subject) {
    final todayEntries = getEntriesByDate(DateTime.now());
    final cleanSubject = subject.trim().toLowerCase();
    for (final entry in todayEntries) {
      if (entry.subjectOrSkill.trim().toLowerCase() == cleanSubject) {
        return entry;
      }
    }
    return null;
  }

  /// Returns a Set of subject/skill names that already have entries today.
  static Set<String> getTodayCheckedInSubjects() {
    final todayEntries = getEntriesByDate(DateTime.now());
    return todayEntries.map((e) => e.subjectOrSkill.trim().toLowerCase()).toSet();
  }

  // GOALS (Partitioned by active profile)
  static Future<void> addGoal(Goal goal) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(goalsBox);
    List goals = box.get('goals_$email') ?? [];
    goals.add(goal.toMap());
    await box.put('goals_$email', goals);
    await BackupService.createBackup();
  }

  static Future<void> updateGoal(Goal goal) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(goalsBox);
    List goals = box.get('goals_$email') ?? [];
    final index = goals.indexWhere((g) => g['id'] == goal.id);
    if (index != -1) {
      goals[index] = goal.toMap();
      await box.put('goals_$email', goals);
      await BackupService.createBackup();
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(goalsBox);
    List goals = box.get('goals_$email') ?? [];
    goals.removeWhere((g) => g['id'] == goalId);
    await box.put('goals_$email', goals);
    await BackupService.createBackup();
  }

  static List<Goal> getAllGoals() {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(goalsBox);
    final goals = box.get('goals_$email') ?? [];
    return goals.map((g) => Goal.fromMap(g.cast<String, dynamic>())).toList();
  }

  static List<Goal> getActiveGoals() {
    return getAllGoals().where((g) => g.status == 'active').toList();
  }

  static List<Goal> getCompletedGoals() {
    return getAllGoals().where((g) => g.status == 'done').toList();
  }

  // STREAKS (Partitioned by active profile)
  static Future<void> saveStreak(Streak streak) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<Map>(streaksBox);
    await box.put('streak_$email', streak.toMap());
    await BackupService.createBackup();
  }

  static Streak? getStreak() {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<Map>(streaksBox);
    final data = box.get('streak_$email');
    if (data == null) return null;
    return Streak.fromMap(data.cast<String, dynamic>());
  }

  // BADGES (Partitioned by active profile)
  static Future<void> addBadge(String badge) async {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(badgesBox);
    List badges = box.get('badges_$email') ?? [];
    if (!badges.contains(badge)) {
      badges.add(badge);
      await box.put('badges_$email', badges);
      await BackupService.createBackup();
    }
  }

  static List<String> getBadges() {
    final email = getActiveUserEmail() ?? 'default';
    final box = Hive.box<List>(badgesBox);
    final badges = box.get('badges_$email') ?? [];
    return badges.cast<String>();
  }

  // CLEAR ALL DATA
  static Future<void> clearAllData() async {
    await Hive.deleteBoxFromDisk(userProfileBox);
    await Hive.deleteBoxFromDisk(entriesBox);
    await Hive.deleteBoxFromDisk(goalsBox);
    await Hive.deleteBoxFromDisk(streaksBox);
    await Hive.deleteBoxFromDisk(badgesBox);
    await initHive();
  }
}
