import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:study_zen/models/subject_model.dart';
import 'package:study_zen/utils/global.dart';

class SubjectService {
  const SubjectService();

  Future<String?> _getAccessToken() async {
    // On web, fall back to in-memory token since secure
    // storage plugins are not available there.
    if (kIsWeb) return accessToken;
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'access');
  }

  Future<List<SubjectModel>> fetchSubjects() async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(
      Uri.parse('$uri/api/subjects/'),
      headers: headers,
    );

    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(body);
      return data.map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractError(body));
    }
  }

  Future<Map<String, dynamic>> createSubject(String name, String description) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('$uri/api/subjects/'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(body);
      return {'success': true, 'subject': SubjectModel.fromJson(data)};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> updateSubject(int id, String name, String description,
      {bool? isCompleted}) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final payload = <String, dynamic>{
      'name': name,
      'description': description,
    };
    if (isCompleted != null) {
      payload['is_completed'] = isCompleted;
    }

    final response = await http.patch(
      Uri.parse('$uri/api/subjects/$id/'),
      headers: headers,
      body: jsonEncode(payload),
    );

    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(body);
      return {'success': true, 'subject': SubjectModel.fromJson(data)};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> enrollInSubject(int id) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('$uri/api/subjects/$id/enroll/'),
      headers: headers,
    );

    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Backend returns a simple {"detail": "..."} payload.
      try {
        final decoded = jsonDecode(body);
        final message = decoded is Map<String, dynamic> && decoded['detail'] != null
            ? decoded['detail'].toString()
            : 'Enrolled successfully';
        return {'success': true, 'message': message};
      } catch (_) {
        return {'success': true, 'message': 'Enrolled successfully'};
      }
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> unenrollFromSubject(int id) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.delete(
      Uri.parse('$uri/api/subjects/$id/enroll/'),
      headers: headers,
    );

    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(body);
        final message = decoded is Map<String, dynamic> && decoded['detail'] != null
            ? decoded['detail'].toString()
            : 'You have been unenrolled from this course';
        return {'success': true, 'message': message};
      } catch (_) {
        return {'success': true, 'message': 'You have been unenrolled from this course'};
      }
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> deleteSubject(int id) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.delete(
      Uri.parse('$uri/api/subjects/$id/'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true};
    } else {
      return {'success': false, 'error': _extractError(response.body)};
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
