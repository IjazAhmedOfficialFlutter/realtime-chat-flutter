import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';

class AuthApi {
  final ApiClient _apiClient;

  AuthApi(this._apiClient);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        response.data?['message']?.toString() ??
            'Login failed.',
      );
    }

    final data = response.data;

    if (data == null) {
      throw Exception('Invalid login response.');
    }

    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        response.data?['message']?.toString() ??
            'Registration failed.',
      );
    }

    final data = response.data;

    if (data == null) {
      throw Exception('Invalid registration response.');
    }

    return data;
  }

  Future<Map<String, dynamic>> getMe({
    required String token,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.me,
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(
        response.data?['message']?.toString() ??
            'Could not load user.',
      );
    }

    final data = response.data;

    if (data == null) {
      throw Exception('Invalid user response.');
    }

    return data;
  }
}