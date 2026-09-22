import 'package:flutter/cupertino.dart';

import '../../core/api/auth_api.dart';
import '../../core/storage/app_preferences.dart';
import '../../model/user_model.dart';

import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;
  final AppPreferences _preferences;

  AuthRepositoryImpl(
      this._authApi,
      this._preferences,
      );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _authApi.login(
      email: email,
      password: password,
    );

    final token = data['token']?.toString();
    final userData = data['user'];

    if (token == null ||
        token.isEmpty ||
        userData is! Map) {
      throw Exception('Invalid login response.');
    }

    final user = UserModel.fromJson(
      Map<String, dynamic>.from(userData),
    );

    await _preferences.saveAuth(
      token: token,
      userId: user.id,
      name: user.name,
      email: user.email,
    );
    debugPrint('SAVED AUTH: userId=${user.id}');
    return user;
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _authApi.register(
      name: name,
      email: email,
      password: password,
    );

    return login(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final id = _preferences.userId;
    final name = _preferences.userName;
    final email = _preferences.userEmail;

    if (id == null ||
        name == null ||
        email == null) {
      return null;
    }

    return UserModel(
      id: id,
      name: name,
      email: email,
    );
  }

  @override
  Future<void> logout() {
    return _preferences.clearAuth();
  }

  @override
  bool get isLoggedIn => _preferences.isLoggedIn;
}