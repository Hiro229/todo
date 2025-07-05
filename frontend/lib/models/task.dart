enum Priority {
  high(1, 'High'),
  medium(2, 'Medium'),
  low(3, 'Low');

  const Priority(this.value, this.label);
  final int value;
  final String label;

  static Priority fromValue(int value) {
    switch (value) {
      case 1:
        return Priority.high;
      case 2:
        return Priority.medium;
      case 3:
        return Priority.low;
      default:
        return Priority.medium;
    }
  }
}

class Category {
  final int id;
  final String name;
  final String? color;
  final DateTime createdAt;

  Category({required this.id, required this.name, this.color, required this.createdAt});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color, 'created_at': createdAt.toIso8601String()};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CategoryCreate {
  final String name;
  final String? color;

  CategoryCreate({required this.name, this.color});

  Map<String, dynamic> toJson() {
    return {'name': name, 'color': color};
  }
}

class Task {
  final int id;
  final String title;
  final String? description;
  final bool isCompleted;
  final Priority priority;
  final DateTime? dueDate;
  final int? categoryId;
  final Category? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    this.dueDate,
    this.categoryId,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['is_completed'],
      priority: Priority.fromValue(json['priority'] ?? 2),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      categoryId: json['category_id'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority.value,
      'due_date': dueDate?.toIso8601String(),
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    DateTime? dueDate,
    int? categoryId,
    Category? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }
}

class TaskCreate {
  final String title;
  final String? description;
  final Priority priority;
  final DateTime? dueDate;
  final int? categoryId;

  TaskCreate({
    required this.title,
    this.description,
    this.priority = Priority.medium,
    this.dueDate,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority.value,
      'due_date': dueDate?.toIso8601String(),
      'category_id': categoryId,
    };
  }
}

class TaskUpdate {
  final String? title;
  final String? description;
  final bool? isCompleted;
  final Priority? priority;
  final DateTime? dueDate;
  final int? categoryId;

  TaskUpdate({
    this.title,
    this.description,
    this.isCompleted,
    this.priority,
    this.dueDate,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (isCompleted != null) data['is_completed'] = isCompleted;
    if (priority != null) data['priority'] = priority!.value;
    if (dueDate != null) data['due_date'] = dueDate!.toIso8601String();
    if (categoryId != null) data['category_id'] = categoryId;
    return data;
  }
}
