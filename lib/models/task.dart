class Task {
  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.userId,
    required this.status,
    this.isSynced = false,
  });

  final String? id;
  final String title;
  final String description;
  final String date;
  final String userId;
  final String status;
  final bool isSynced;

  bool get isCompleted => status == 'completed' || status == 'done';
  bool get isPending => status == 'pending' || status == 'todo';

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? userId,
    String? status,
    bool? isSynced,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '1',
      status: json['status']?.toString() ?? 'pending',
      isSynced: json['isSynced'] == true || json['isSynced'] == 1,
    );
  }

  factory Task.fromDb(Map<String, dynamic> map) => Task(
        id: map['id']?.toString(),
        title: map['title'] as String,
        description: map['description'] as String,
        date: map['date'] as String,
        userId: map['userId'] as String,
        status: map['status'] as String,
        isSynced: (map['isSynced'] as int) == 1,
      );

  Map<String, dynamic> toJson() => {
        if (id != null && !_isLocalId(id!)) 'id': id,
        'title': title,
        'description': description,
        'date': date,
        'userId': userId,
        'status': status,
      };

  Map<String, dynamic> toDb() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date,
        'userId': userId,
        'status': status,
        'isSynced': isSynced ? 1 : 0,
      };

  static bool _isLocalId(String value) => value.startsWith('local_');
}
