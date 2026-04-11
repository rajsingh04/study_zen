class SubmissionModel {
  final int id;
  final int? assignmentId;
  final int? studentId;
  final String? fileUrl;
  final String? comments;
  final DateTime? submittedAt;
  final String? grade;

  SubmissionModel({
    required this.id,
    this.assignmentId,
    this.studentId,
    this.fileUrl,
    this.comments,
    this.submittedAt,
    this.grade,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    return SubmissionModel(
      id: json['id'] ?? 0,
      assignmentId: json['assignment'] is int ? json['assignment'] as int : null,
      studentId: json['student'] is int ? json['student'] as int : null,
      fileUrl: json['file'] as String?,
      comments: json['comments'] as String?,
      submittedAt: parseDate(json['submitted_at'] ?? json['submittedAt']),
      grade: json['grade'] as String?,
    );
  }
}
