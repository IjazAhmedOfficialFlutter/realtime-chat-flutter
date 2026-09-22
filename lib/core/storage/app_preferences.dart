import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';

  final SharedPreferences _preferences;

  AppPreferences(this._preferences);

  Future<void> saveAuth({
    required String token,
    required int userId,
    required String name,
    required String email,
  }) async {
    await _preferences.setString(tokenKey, token);
    await _preferences.setInt(userIdKey, userId);
    await _preferences.setString(userNameKey, name);
    await _preferences.setString(userEmailKey, email);
  }

  String? get token =>
      _preferences.getString(tokenKey);

  int? get userId =>
      _preferences.getInt(userIdKey);

  String? get userName =>
      _preferences.getString(userNameKey);

  String? get userEmail =>
      _preferences.getString(userEmailKey);

  bool get isLoggedIn =>
      token != null && token!.isNotEmpty;

  Future<void> clearAuth() async {
    await _preferences.remove(tokenKey);
    await _preferences.remove(userIdKey);
    await _preferences.remove(userNameKey);
    await _preferences.remove(userEmailKey);
  }
}