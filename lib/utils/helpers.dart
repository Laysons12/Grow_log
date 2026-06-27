import 'package:intl/intl.dart';

class AppHelpers {
  // Format date to readable format
  static String formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  // Format time to HH:mm
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  // Format date for calendar display
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  // Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '🌅 Good Morning';
    } else if (hour < 17) {
      return '☀️ Good Afternoon';
    } else {
      return '🌙 Good Evening';
    }
  }

  // Calculate days since date
  static int daysSince(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Get relative date string
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }

  // Parse time string to DateTime
  static DateTime parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  // Get emoji for focus level
  static String getFocusEmoji(int level) {
    switch (level) {
      case 1:
        return '😴';
      case 2:
        return '😐';
      case 3:
        return '😊';
      case 4:
        return '😄';
      case 5:
        return '🔥';
      default:
        return '😐';
    }
  }

  // Get emoji for energy level
  static String getEnergyEmoji(int level) {
    switch (level) {
      case 1:
        return '🥱';
      case 2:
        return '😐';
      case 3:
        return '😊';
      case 4:
        return '⚡';
      case 5:
        return '💪';
      default:
        return '😐';
    }
  }

  // Get emoji for mood
  static String getMoodEmoji(String mood) {
    const moodEmojis = {
      'focused': '🎯',
      'tired': '😴',
      'motivated': '🚀',
      'stressed': '😰',
      'calm': '🧘',
      'energized': '⚡',
    };
    return moodEmojis[mood.toLowerCase()] ?? '😐';
  }

  // Format hours as readable string
  static String formatHours(double hours) {
    if (hours == hours.toInt()) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  // Get status color (for goals)
  static String getStatusEmoji(String status) {
    switch (status) {
      case 'not_started':
        return '⭕';
      case 'in_progress':
        return '🔄';
      case 'done':
        return '✅';
      default:
        return '❓';
    }
  }

  // Calculate streak days from entries
  static int calculateCurrentStreak(List<DateTime> entryDates) {
    if (entryDates.isEmpty) return 0;

    // Deduplicate by calendar day
    final uniqueDays = <String>{};
    final List<DateTime> uniqueDates = [];
    for (var date in entryDates) {
      final dayKey = '${date.year}-${date.month}-${date.day}';
      if (!uniqueDays.contains(dayKey)) {
        uniqueDays.add(dayKey);
        uniqueDates.add(DateTime(date.year, date.month, date.day));
      }
    }

    uniqueDates.sort((a, b) => b.compareTo(a)); // Most recent first

    int streak = 0;
    DateTime? lastDate;

    for (var date in uniqueDates) {
      if (lastDate == null) {
        // First entry
        if (isToday(date) || isYesterday(date)) {
          streak = 1;
          lastDate = date;
        } else {
          return 0; // Streak broken
        }
      } else {
        // Check if consecutive
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (date.year == expectedDate.year &&
            date.month == expectedDate.month &&
            date.day == expectedDate.day) {
          streak++;
          lastDate = date;
        } else {
          break; // Streak broken
        }
      }
    }

    return streak;
  }
}
