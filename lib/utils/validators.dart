class AppValidators {
  // 1. Name Validator
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    final name = value.trim();
    if (value != name) {
      return 'Name cannot have leading or trailing spaces';
    }
    final nameRegex = RegExp(r'^[a-zA-Z ]+$');
    if (!nameRegex.hasMatch(name)) {
      return 'Name can only contain letters';
    }
    if (name.length > 25) {
      return 'Name must be 25 characters or less';
    }
    return null;
  }

  // 2. Username Validator
  static String? validateUsername(String? value, {bool Function(String)? isTaken}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }
    final username = value.trim();
    if (value != username) {
      return 'Username cannot have leading or trailing spaces';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters and numbers';
    }
    if (username.length > 25) {
      return 'Username must be 25 characters or less';
    }
    final digitCount = username.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount > 4) {
      return 'Username can have at most 4 numbers';
    }
    if (isTaken != null && isTaken(username)) {
      return 'This username is already taken, please choose another';
    }
    return null;
  }

  // 3. Email Validator
  static String? validateEmail(String? value, {bool Function(String)? isTaken}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final email = value.trim();
    if (value != email) {
      return 'Email cannot have leading or trailing spaces';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    if (isTaken != null && isTaken(email)) {
      return 'This email address is already registered';
    }
    return null;
  }

  // 4. Role or Class Validator
  static String? validateRoleOrClass(String? value, String mode) {
    if (value == null || value.trim().isEmpty) {
      return mode == 'student'
          ? 'Please enter your class or college'
          : 'Please enter your current role';
    }
    final role = value.trim();
    if (value != role) {
      return 'Value cannot have leading or trailing spaces';
    }
    final allowedRegex = RegExp(r"^[a-zA-Z0-9 .,&'-]+$");
    if (!allowedRegex.hasMatch(role)) {
      return 'Contains invalid characters';
    }
    final letterCount = role.replaceAll(RegExp(r"[^a-zA-Z]"), '').length;
    if (letterCount > 25) {
      return mode == 'student'
          ? 'Class/College can have at most 25 letters'
          : 'Role can have at most 25 letters';
    }
    final digitCount = role.replaceAll(RegExp(r"[^0-9]"), '').length;
    if (digitCount > 3) {
      return mode == 'student'
          ? 'Class/College can have at most 3 numbers'
          : 'Role can have at most 3 numbers';
    }
    return null;
  }

  // 5. Skills or Subjects List Validator
  static String? validateSkillsOrSubjects(List<String> list) {
    if (list.isEmpty) {
      return 'Please select at least one topic';
    }
    if (list.length > 6) {
      return 'You can select at most 6 topics';
    }
    final seen = <String>{};
    for (final item in list) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) {
        return 'Topic cannot be empty';
      }
      final letterCount = trimmed.replaceAll(RegExp(r"[^a-zA-Z]"), '').length;
      if (letterCount < 3) {
        return 'Topic must have at least 3 letters';
      }
      if (letterCount > 20) {
        return 'Topic can have at most 20 letters';
      }
      final digitCount = trimmed.replaceAll(RegExp(r"[^0-9]"), '').length;
      if (digitCount > 3) {
        return 'Topic can have at most 3 numbers';
      }
      final allowedRegex = RegExp(r"^[a-zA-Z0-9 .,&'-]+$");
      if (!allowedRegex.hasMatch(trimmed)) {
        return 'Topic contains invalid characters';
      }
      if (seen.contains(trimmed.toLowerCase())) {
        return 'Duplicate topics are not allowed';
      }
      seen.add(trimmed.toLowerCase());
    }
    return null;
  }

  // 6. Reminder Time Validator
  static String? validateReminderTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a reminder time';
    }
    final time = value.trim();
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!timeRegex.hasMatch(time)) {
      return 'Reminder time must be in HH:mm 24-hour format';
    }
    return null;
  }

  // 7. Duration Hours Validator
  static String? validateDurationHours(double? value) {
    if (value == null) {
      return 'Please enter study/learning hours';
    }
    if (value <= 0) {
      return 'Hours must be greater than 0';
    }
    if (value > 16.0) {
      return 'Hours cannot exceed 16 hours per day';
    }
    return null;
  }

  // 8. Mood Validator
  static String? validateMood(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a mood';
    }
    final mood = value.trim().toLowerCase();
    const allowedMoods = ['focused', 'tired', 'motivated', 'stressed', 'calm', 'energized'];
    if (!allowedMoods.contains(mood)) {
      return 'Invalid mood selection';
    }
    return null;
  }

  // 9. Notes Validator (doubts, win, improve)
  static String? validateNotes(String? value, {String fieldName = 'Notes'}) {
    if (value != null && value.length > 500) {
      return '$fieldName must be 500 characters or less';
    }
    return null;
  }

  // 9a. Win of the Day Validator
  static String? validateWin(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    final digitCount = trimmed.replaceAll(RegExp(r"[^0-9]"), "").length;
    if (digitCount > 5) {
      return 'Win of the day can have at most 5 numbers';
    }
    final letterCount = trimmed.replaceAll(RegExp(r"[^a-zA-Z]"), "").length;
    if (letterCount > 200) {
      return 'Win of the day can have at most 200 letters';
    }
    return null;
  }

  // 9b. What to Improve Validator
  static String? validateImprove(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    final digitCount = trimmed.replaceAll(RegExp(r"[^0-9]"), "").length;
    if (digitCount > 15) {
      return 'What to improve can have at most 15 numbers';
    }
    return null;
  }

  // 9c. Doubts to Clear Validator
  static String? validateDoubts(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    final digitCount = trimmed.replaceAll(RegExp(r"[^0-9]"), "").length;
    if (digitCount > 20) {
      return 'Doubts can have at most 20 numbers';
    }
    return null;
  }

  // 10. Goal Title Validator
  static String? validateGoalTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a goal title';
    }
    final title = value.trim();
    if (title.length > 60) {
      return 'Goal title must be 60 characters or less';
    }
    return null;
  }
}
