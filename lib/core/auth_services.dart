import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.110.180:5082';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    print('LOGIN URL: $uri');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      print('LOGIN STATUS: ${response.statusCode}');

      print('LOGIN RESPONSE: ${response.body}');

      final data = _decodeObject(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message']?.toString() ?? 'Login failed.');
      }

      final token = data['token']?.toString();
      final user = data['user'];

      if (token == null || token.isEmpty || user is! Map) {
        throw Exception('Invalid login response.');
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(tokenKey, token);

      await prefs.setString(
        userKey,
        jsonEncode(Map<String, dynamic>.from(user)),
      );

      print('LOGIN SAVED SUCCESSFULLY');

      return data;
    } on SocketException catch (e) {
      print('LOGIN SOCKET ERROR: $e');

      throw Exception('Cannot connect to server.');
    } on HttpException catch (e) {
      print('LOGIN HTTP ERROR: $e');

      throw Exception('Server connection failed.');
    } on FormatException catch (e) {
      print('LOGIN JSON ERROR: $e');

      throw Exception('Invalid server response.');
    } on TimeoutException {
      print('LOGIN TIMEOUT');

      throw Exception('Server connection timed out.');
    } catch (e) {
      print('LOGIN ERROR: $e');
      rethrow;
    }
  }



  Future<void> testSocket() async {
    debugPrint('SOCKET TEST START');

    Socket? socket;

    try {
      socket = await Socket.connect(
        '192.168.110.180',
        5082,
        timeout: const Duration(seconds: 5),
      );

      debugPrint('SOCKET CONNECTED');
    } on SocketException catch (e) {
      debugPrint('SOCKET ERROR: $e');
      rethrow;
    } on TimeoutException {
      debugPrint('SOCKET TIMEOUT');
      rethrow;
    } finally {
      socket?.destroy();
    }
  }


  Future<void> testNativeGet() async {
    final client = HttpClient();

    try {
      debugPrint('NATIVE GET START');

      final request = await client
          .getUrl(
        Uri.parse(
          'http://192.168.110.180:5082/',
        ),
      );



      debugPrint('NATIVE REQUEST CREATED $request');

      final response = await request.close();

      debugPrint(
        'NATIVE STATUS: ${response.statusCode}',
      );

      final body =
      await response.transform(
        const SystemEncoding().decoder,
      ).join();

      debugPrint(
        'NATIVE BODY: $body',
      );
    } catch (e) {
      debugPrint(
        'NATIVE GET ERROR: $e',
      );
    } finally {
      client.close();
    }
  }
  Future<void> testGet() async {
    final uri = Uri.parse(
      '$baseUrl/',
    );

    debugPrint('GET START: $uri');

    try {
      final response = await http
          .get(uri)
          .timeout(
        const Duration(seconds: 15),
      );

      debugPrint(
        'GET STATUS: ${response.statusCode}',
      );

      debugPrint(
        'GET BODY: ${response.body}',
      );
    } catch (e) {
      debugPrint('GET ERROR: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(userKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    final data = jsonDecode(value);

    if (data is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(data);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getMessages(int otherUserId) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication required.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/messages/$otherUserId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Could not load messages.');
    }

    if (data is! List) {
      throw Exception('Invalid message response.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  Map<String, dynamic> _decodeObject(String body) {
    final data = jsonDecode(body);

    if (data is! Map) {
      throw Exception('Invalid server response.');
    }

    return Map<String, dynamic>.from(data);
  }
}
