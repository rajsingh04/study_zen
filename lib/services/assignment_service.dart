import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:study_zen/models/assignment_model.dart';
import 'package:study_zen/models/submission_model.dart';
import 'package:study_zen/utils/global.dart';


class AssignmentService {
  const AssignmentService();

  Future<String?> _getAccessToken() async {
    if (kIsWeb) return accessToken;
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'access');
  }

  Future<List<AssignmentModel>> fetchAssignments({int? subjectId}) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final endpoint = subjectId == null
      ? Uri.parse('$uri/api/assignments/')
      : Uri.parse('$uri/api/assignments/?subject=$subjectId');

    final response = await http.get(endpoint, headers: headers);
    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(body);
      return data.map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractError(body));
    }
  }

  Future<Map<String, dynamic>> createAssignment({
    required String title,
    String? description,
    required DateTime dueDate,
    required int subjectId,
    File? attachment,
  }) async {
    final token = await _getAccessToken();
    final endpoint = Uri.parse('$uri/api/assignments/');
    final request = http.MultipartRequest('POST', endpoint);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    request.fields['due_date'] = dueDate.toUtc().toIso8601String();
    request.fields['subject'] = subjectId.toString();

    if (attachment != null) {
      final mimeType = lookupMimeType(attachment.path) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'attachment',
        attachment.path,
        contentType: MediaType(parts[0], parts.length > 1 ? parts[1] : ''),
      ));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final body = resp.body;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return {'success': true, 'assignment': AssignmentModel.fromJson(data)};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> updateAssignment({
    required int assignmentId,
    String? title,
    String? description,
    DateTime? dueDate,
    File? attachment,
  }) async {
    final token = await _getAccessToken();
    final endpoint = Uri.parse('$uri/api/assignments/$assignmentId/');
    final request = http.MultipartRequest('PATCH', endpoint);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (dueDate != null) request.fields['due_date'] = dueDate.toUtc().toIso8601String();

    if (attachment != null) {
      final mimeType = lookupMimeType(attachment.path) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'attachment',
        attachment.path,
        contentType: MediaType(parts[0], parts.length > 1 ? parts[1] : ''),
      ));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final body = resp.body;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return {'success': true, 'assignment': AssignmentModel.fromJson(data)};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> deleteAssignment(int assignmentId) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final endpoint = Uri.parse('$uri/api/assignments/$assignmentId/');
    final resp = await http.delete(endpoint, headers: headers);
    final body = resp.body;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<List<SubmissionModel>> fetchSubmissions(int assignmentId) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(Uri.parse('$uri/api/assignments/$assignmentId/submissions/'), headers: headers);
    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(body);
      return data.map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractError(body));
    }
  }

  Future<Map<String, dynamic>> submitAssignment({required int assignmentId, File? file, String? comments}) async {
    final token = await _getAccessToken();
    final endpoint = Uri.parse('$uri/api/assignments/$assignmentId/submissions/');
    final request = http.MultipartRequest('POST', endpoint);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (comments != null) request.fields['comments'] = comments;

    if (file != null) {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(parts[0], parts.length > 1 ? parts[1] : ''),
      ));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final body = resp.body;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return {'success': true, 'submission': SubmissionModel.fromJson(data)};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  String _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('detail')) return decoded['detail'].toString();
        if (decoded.values.isNotEmpty) {
          final first = decoded.values.first;
          return first is String ? first : first.toString();
        }
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}

// Helper: small mime lookup
String? lookupMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return null;
  }
}
