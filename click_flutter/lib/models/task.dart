enum Priority { high, medium, low }

enum RecurrenceType { daily, weekly, monthly, none }

class Subtask {
  String id;
  String title;
  bool completed;

  Subtask({required this.id, required this.title, this.completed = false});

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'completed': completed};
  }

  Subtask copyWith({String? id, String? title, bool? completed}) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

class Task {
  String id;
  String title;
  String description;
  Priority priority;
  String category;
  DateTime? deadline;
  RecurrenceType recurrence;
  List<Subtask> subtasks;
  bool completed;
  DateTime? completedAt;
  DateTime createdAt;
  String notes;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    this.category = 'Other',
    this.deadline,
    this.recurrence = RecurrenceType.none,
    this.subtasks = const [],
    this.completed = false,
    this.completedAt,
    required this.createdAt,
    this.notes = '',
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priority: Priority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      category: json['category'] as String? ?? 'Other',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((e) => Subtask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'category': category,
      'deadline': deadline?.toIso8601String(),
      'recurrence': recurrence.name,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    Priority? priority,
    String? category,
    DateTime? deadline,
    RecurrenceType? recurrence,
    List<Subtask>? subtasks,
    bool? completed,
    DateTime? completedAt,
    DateTime? createdAt,
    String? notes,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      recurrence: recurrence ?? this.recurrence,
      subtasks: subtasks ?? this.subtasks,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

class AppConstants {
  static const List<String> categories = [
    'Work',
    'Study',
    'Personal',
    'Health',
    'Finance',
    'Errands',
    'Other',
  ];
}
