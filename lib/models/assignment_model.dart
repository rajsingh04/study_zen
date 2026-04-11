class AssignmentModel {
  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? attachmentUrl;
  final int? ownerId;
  final int? subjectId;
  final String? subjectName;
  final DateTime? createdAt;

  AssignmentModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.attachmentUrl,
    this.ownerId,
    this.subjectId,
    this.subjectName,
    this.createdAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    return AssignmentModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] as String?,
      dueDate: parseDate(json['due_date'] ?? json['dueDate']),
      attachmentUrl: json['attachment'] as String?,
      ownerId: json['owner'] is int ? json['owner'] as int : null,
      subjectId: json['subject'] is int ? json['subject'] as int : null,
      subjectName: json['subject_name'] as String?,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }
}
