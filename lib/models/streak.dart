class Streak {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastEntryDate;

  Streak({
    required int currentStreak,
    required int longestStreak,
    required this.lastEntryDate,
  })  : currentStreak = currentStreak < 0 ? 0 : currentStreak,
        longestStreak = longestStreak < (currentStreak < 0 ? 0 : currentStreak)
            ? (currentStreak < 0 ? 0 : currentStreak)
            : longestStreak;

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastEntryDate': lastEntryDate.toIso8601String(),
    };
  }

  // Create from Map
  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastEntryDate: map['lastEntryDate'] != null
          ? DateTime.parse(map['lastEntryDate'])
          : DateTime.now(),
    );
  }

  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastEntryDate,
  }) {
    return Streak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastEntryDate: lastEntryDate ?? this.lastEntryDate,
    );
  }

  // Check if streak is still active (entry added today or yesterday)
  bool get isActive {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return lastEntryDate.year == now.year &&
            lastEntryDate.month == now.month &&
            lastEntryDate.day == now.day ||
        lastEntryDate.year == yesterday.year &&
            lastEntryDate.month == yesterday.month &&
            lastEntryDate.day == yesterday.day;
  }
}
