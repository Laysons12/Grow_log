class Goal {
  final String id;
  final String text; // goal description
  final String linkedTo; // linked subject/skill
  final DateTime dueDate;
  final String status; // 'not_started', 'in_progress', 'done'
  final DateTime createdAt;
  final DateTime? completedAt;

  Goal({
    String? id,
    required this.text,
    required this.linkedTo,
    required this.dueDate,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        status = (status == 'done') ? 'done' : 'active',
        createdAt = createdAt ?? DateTime.now(),
        completedAt = (status == 'done') ? (completedAt ?? DateTime.now()) : null;

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'linkedTo': linkedTo,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create from Map
  factory Goal.fromMap(Map<String, dynamic> map) {
    final statusVal = map['status'];
    final normalizedStatus = (statusVal == 'done') ? 'done' : 'active';
    return Goal(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      linkedTo: map['linkedTo'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      status: normalizedStatus,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  Goal copyWith({
    String? id,
    String? text,
    String? linkedTo,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      text: text ?? this.text,
      linkedTo: linkedTo ?? this.linkedTo,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isCompleted => status == 'done';

  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(dueDate);
  }
}
