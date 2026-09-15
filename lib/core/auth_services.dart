import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'http://192.168.110.180:5082';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid email or password.');
    }

    final data = jsonDecode(response.body);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      tokenKey,
      data['token'],
    );

    await prefs.setString(
      userKey,
      jsonEncode(data['user']),
    );

    return data;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(userKey);

    if (value == null) {
      return null;
    }

    return jsonDecode(value);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }
}