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
