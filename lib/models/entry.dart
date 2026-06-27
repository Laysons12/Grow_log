import '../utils/validators.dart';

class Entry {
  final String id;
  final DateTime date;
  final String mode; // 'student' or 'professional'
  final String learned; // what they studied/learned
  final String subjectOrSkill; // which subject/skill
  final double hoursOrEnergy; // hours studied or learning hours
  final String moodOrFocus; // mood/focus details
  final String win; // one win of the day
  final String improve; // what to improve
  final String? doubts; // (student only) doubts to clear
  final double energyLevel; // energy level for professionals (1-5)

  Entry({
    String? id,
    required this.date,
    required this.mode,
    required this.learned,
    required this.subjectOrSkill,
    required double hoursOrEnergy,
    required this.moodOrFocus,
    required this.win,
    required this.improve,
    this.doubts,
    double? energyLevel,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        hoursOrEnergy = (hoursOrEnergy * 100).round() / 100,
        energyLevel = energyLevel ?? (mode == 'professional' ? ((hoursOrEnergy * 100).round() / 100) : 3.0) {
    if (date.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      throw ArgumentError('Entry date cannot be in the future.');
    }
    if (mode != 'student' && mode != 'professional') {
      throw ArgumentError('Invalid mode: must be student or professional');
    }
    final hoursError = AppValidators.validateDurationHours(this.hoursOrEnergy);
    if (hoursError != null) throw ArgumentError(hoursError);

    if (mode == 'professional') {
      final moodError = AppValidators.validateMood(moodOrFocus);
      if (moodError != null) throw ArgumentError(moodError);
    } else {
      final val = double.tryParse(moodOrFocus);
      if (val == null || val < 1 || val > 5) {
        throw ArgumentError('Invalid focus level: must be between 1 and 5');
      }
    }

    final learnedError = AppValidators.validateNotes(learned, fieldName: 'Learned');
    if (learnedError != null) throw ArgumentError(learnedError);

    final winError = AppValidators.validateWin(win);
    if (winError != null) throw ArgumentError(winError);

    final improveError = AppValidators.validateImprove(improve);
    if (improveError != null) throw ArgumentError(improveError);

    if (doubts != null) {
      final doubtsError = AppValidators.validateDoubts(doubts);
      if (doubtsError != null) throw ArgumentError(doubtsError);
    }
  }

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mode': mode,
      'learned': learned,
      'subjectOrSkill': subjectOrSkill,
      'hoursOrEnergy': hoursOrEnergy,
      'moodOrFocus': moodOrFocus,
      'win': win,
      'improve': improve,
      'doubts': doubts,
      'energyLevel': energyLevel,
    };
  }

  // Create from Map
  factory Entry.fromMap(Map<String, dynamic> map) {
    final modeVal = map['mode'] ?? 'student';
    final rawHoursOrEnergy = (map['hoursOrEnergy'] ?? 0).toDouble();
    return Entry(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date']),
      mode: modeVal,
      learned: map['learned'] ?? '',
      subjectOrSkill: map['subjectOrSkill'] ?? '',
      hoursOrEnergy: rawHoursOrEnergy,
      moodOrFocus: map['moodOrFocus'] ?? '',
      win: map['win'] ?? '',
      improve: map['improve'] ?? '',
      doubts: map['doubts'],
      energyLevel: (map['energyLevel'] ?? (modeVal == 'professional' ? rawHoursOrEnergy : 3.0)).toDouble(),
    );
  }

  Entry copyWith({
    String? id,
    DateTime? date,
    String? mode,
    String? learned,
    String? subjectOrSkill,
    double? hoursOrEnergy,
    String? moodOrFocus,
    String? win,
    String? improve,
    String? doubts,
    double? energyLevel,
  }) {
    return Entry(
      id: id ?? this.id,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      learned: learned ?? this.learned,
      subjectOrSkill: subjectOrSkill ?? this.subjectOrSkill,
      hoursOrEnergy: hoursOrEnergy ?? this.hoursOrEnergy,
      moodOrFocus: moodOrFocus ?? this.moodOrFocus,
      win: win ?? this.win,
      improve: improve ?? this.improve,
      doubts: doubts ?? this.doubts,
      energyLevel: energyLevel ?? this.energyLevel,
    );
  }

  // Check if date is today
  bool isToday() {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
