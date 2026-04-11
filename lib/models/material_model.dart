class MaterialModel {
  final int id;
  final String title;
  final String? description;
  final String? fileUrl;
  final int? ownerId;
  final int? subjectId;
  final String? subjectName;
  final DateTime? createdAt;

  MaterialModel({
    required this.id,
    required this.title,
    this.description,
    this.fileUrl,
    this.ownerId,
    this.subjectId,
    this.subjectName,
    this.createdAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    return MaterialModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] as String?,
      fileUrl: json['file'] as String?,
      ownerId: json['owner'] is int ? json['owner'] as int : null,
      subjectId: json['subject'] is int ? json['subject'] as int : null,
      subjectName: json['subject_name'] as String?,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }
}
