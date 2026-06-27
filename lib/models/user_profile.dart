import '../utils/validators.dart';

class UserProfile {
  final String name;
  final String username;
  final String email;
  final String mode; // 'student' or 'professional'
  final String roleOrClass; // college/company role
  final List<String> skillsOrSubjects; // up to 6 subjects/skills
  final String reminderTime; // HH:mm format
  final bool isFirstTime;
  final DateTime createdAt;

  UserProfile({
    required this.name,
    this.username = '',
    required this.email,
    required this.mode,
    required this.roleOrClass,
    required this.skillsOrSubjects,
    required this.reminderTime,
    required this.isFirstTime,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    final nameError = AppValidators.validateName(name);
    if (nameError != null) throw ArgumentError(nameError);

    final usernameError = AppValidators.validateUsername(username);
    if (usernameError != null) throw ArgumentError(usernameError);

    final emailError = AppValidators.validateEmail(email);
    if (emailError != null) throw ArgumentError(emailError);

    if (mode != 'student' && mode != 'professional') {
      throw ArgumentError('Invalid mode selection: must be student or professional');
    }

    final roleError = AppValidators.validateRoleOrClass(roleOrClass, mode);
    if (roleError != null) throw ArgumentError(roleError);

    final skillsError = AppValidators.validateSkillsOrSubjects(skillsOrSubjects);
    if (skillsError != null) throw ArgumentError(skillsError);

    final reminderError = AppValidators.validateReminderTime(reminderTime);
    if (reminderError != null) throw ArgumentError(reminderError);
  }

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'mode': mode,
      'roleOrClass': roleOrClass,
      'skillsOrSubjects': skillsOrSubjects,
      'reminderTime': reminderTime,
      'isFirstTime': isFirstTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      mode: map['mode'] ?? 'student',
      roleOrClass: map['roleOrClass'] ?? '',
      skillsOrSubjects: List<String>.from(map['skillsOrSubjects'] ?? []),
      reminderTime: map['reminderTime'] ?? '09:00',
      isFirstTime: map['isFirstTime'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? mode,
    String? roleOrClass,
    List<String>? skillsOrSubjects,
    String? reminderTime,
    bool? isFirstTime,
    DateTime? createdAt,
  }) {
    if (email != null && email != this.email) {
      throw ArgumentError('Email is immutable post-onboarding.');
    }
    if (username != null && username != this.username) {
      throw ArgumentError('Username is immutable post-onboarding.');
    }
    if (createdAt != null && createdAt != this.createdAt) {
      throw ArgumentError('createdAt is immutable.');
    }

    return UserProfile(
      name: name ?? this.name,
      username: this.username,
      email: this.email,
      mode: mode ?? this.mode,
      roleOrClass: roleOrClass ?? this.roleOrClass,
      skillsOrSubjects: skillsOrSubjects ?? this.skillsOrSubjects,
      reminderTime: reminderTime ?? this.reminderTime,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      createdAt: this.createdAt,
    );
  }
}
