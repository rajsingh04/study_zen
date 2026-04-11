import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:study_zen/models/material_model.dart';
import 'package:study_zen/utils/global.dart';

class MaterialService {
  const MaterialService();

  Future<String?> _getAccessToken() async {
    if (kIsWeb) return accessToken;
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'access');
  }

  Future<List<MaterialModel>> fetchMaterials({int? subjectId}) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final endpoint = subjectId == null
        ? Uri.parse('$uri/api/materials/')
        : Uri.parse('$uri/api/materials/?subject=$subjectId');

    final response = await http.get(endpoint, headers: headers);
    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(body);
      return data.map((e) => MaterialModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractError(body));
    }
  }

  Future<Map<String, dynamic>> createMaterial({
    required String title,
    String? description,
    required int subjectId,
    File? file,
  }) async {
    final token = await _getAccessToken();
    final endpoint = Uri.parse('$uri/api/materials/');
    final request = http.MultipartRequest('POST', endpoint);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    request.fields['subject'] = subjectId.toString();

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
      return {'success': true, 'material': MaterialModel.fromJson(data)};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> updateMaterial({
    required int materialId,
    String? title,
    String? description,
    File? file,
  }) async {
    final token = await _getAccessToken();
    final endpoint = Uri.parse('$uri/api/materials/$materialId/');
    final request = http.MultipartRequest('PATCH', endpoint);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;

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
      return {'success': true, 'material': MaterialModel.fromJson(data)};
    } else {
      return {'success': false, 'error': _extractError(body)};
    }
  }

  Future<Map<String, dynamic>> deleteMaterial(int materialId) async {
    final token = await _getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final endpoint = Uri.parse('$uri/api/materials/$materialId/');
    final resp = await http.delete(endpoint, headers: headers);
    final body = resp.body;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true};
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
