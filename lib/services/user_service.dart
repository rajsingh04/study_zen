import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:study_zen/utils/global.dart';
import 'package:study_zen/models/user_model.dart';

class UserService {
  Future<Map<String, dynamic>> registerUser(
    String name,
    String email,
    String password,
    String accountType,
  ) async {
    try {
      var response = await http.post(
        Uri.parse('$uri/api/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': name,
          'email': email,
          'password': password,
          'account_type': accountType,
        }),
      );
      final body = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(body);
        return {'success': true, 'user': UserModel.fromJson(data)};
      } else {
        // Try to parse JSON error payload from DRF
        try {
          var err = jsonDecode(body);
          String message = '';
          if (err is Map) {
            if (err.containsKey('error')) {
              message = err['error'].toString();
            } else if (err.containsKey('errors')) {
              message = err['errors'].toString();
            } else if (err.containsKey('detail')) {
              message = err['detail'].toString();
            } else if (err.values.isNotEmpty) {
              var first = err.values.first;
              message = first is String ? first : first.toString();
            } else {
              message = err.toString();
            }
          } else {
            message = body;
          }
          message = message.replaceAll(RegExp(r'[\[\]{}"]'), '');
          return {'success': false, 'error': message};
        } catch (e) {
          return {'success': false, 'error': body};
        }
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Returns stored `UserModel` if available, otherwise null.
  Future<UserModel?> getStoredUser() async {
    try {
      if (kIsWeb) return null;
      final storage = FlutterSecureStorage();
      final userJson = await storage.read(key: 'user');
      if (userJson == null) return null;
      final Map<String, dynamic> data = jsonDecode(userJson);
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      var response = await http.post(
        Uri.parse('$uri/api/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      final body = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(body);
        // Persist tokens only on supported platforms (skip web)
        if (!kIsWeb) {
          final storage = FlutterSecureStorage();
          try {
            // Clear any existing tokens
            await storage.delete(key: 'refresh');
            await storage.delete(key: 'access');
            // Save user JSON for auto-login
            if (data.containsKey('user')) {
              await storage.delete(key: 'user');
              await storage.write(key: 'user', value: jsonEncode(data['user']));
            }
            // Write available tokens
            if (data.containsKey('refresh')) {
              await storage.write(key: 'refresh', value: data['refresh']);
            }
            if (data.containsKey('access')) {
              await storage.write(key: 'access', value: data['access']);
            }
          } on MissingPluginException {
            // Plugin not registered for this platform — ignore silently.
          } catch (e) {
            log("Error storing token: $e");
          }
        }
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        try {
          var err = jsonDecode(body);
          String message = '';
          if (err is Map) {
            if (err.containsKey('error')) {
              message = err['error'].toString();
            } else if (err.containsKey('errors')) {
              message = err['errors'].toString();
            } else if (err.containsKey('detail')) {
              message = 'Invalid credentials.';
            } else if (err.values.isNotEmpty) {
              var first = err.values.first;
              message = first is String ? first : first.toString();
            } else {
              message = err.toString();
            }
          } else {
            message = body;
          }
          return {'success': false, 'error': message};
        } catch (e) {
          return {'success': false, 'error': body};
        }
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  Future<void> logout() async {
        try {
          if (kIsWeb) {
            // Clear in-memory tokens used on web
            accessToken = null;
            refreshToken = null;
          } else {
            final storage = FlutterSecureStorage();
            await storage.delete(key: 'user');
            await storage.delete(key: 'access');
            await storage.delete(key: 'refresh');
          }
        } catch (e) {
          log('Error during logout: $e');
        }
      }
}
