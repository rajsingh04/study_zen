class SubjectModel {
  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final String? ownerName;
  final bool isCompleted;
  final int enrolledCount;

  SubjectModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.ownerName,
    this.isCompleted = false,
    this.enrolledCount = 0,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    String? ownerName;
    int ownerId = 0;
    final owner = json['owner'];
    if (owner is int) {
      ownerId = owner;
    } else if (owner is Map<String, dynamic>) {
      ownerId = owner['id'] as int? ?? 0;
      ownerName = owner['username'] as String? ?? owner['email'] as String?;
    }

    // Fallback if backend sends a flat owner_name field instead of
    // a nested owner object.
    ownerName ??= json['owner_name'] as String?;

    final isCompleted =
        (json['is_completed'] is bool ? json['is_completed'] as bool : null) ??
        (json['isCompleted'] is bool ? json['isCompleted'] as bool : null) ??
        false;

    int enrolledCount = 0;
    final enrolled = json['enrolled_students'];
    if (enrolled is List) {
      enrolledCount = enrolled.length;
    }

    return SubjectModel(
      id: json['id'] ?? 0,
      ownerId: ownerId,
      name: json['name'] ?? '',
      description: json['description'],
      ownerName: ownerName,
      isCompleted: isCompleted,
      enrolledCount: enrolledCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner': ownerId,
      'name': name,
      'description': description,
      'is_completed': isCompleted,
      // ownerName is derived from backend response; it's not required when sending data back
    };
  }
}
