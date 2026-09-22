import 'package:dio/dio.dart';

import '../storage/app_preferences.dart';
import 'api_constants.dart';
import 'api_headers.dart';

class ApiClient {
  final Dio dio;
  final AppPreferences _preferences;

  ApiClient(
      this.dio,
      this._preferences,
      );

  Future<Response<T>> get<T>(
      String path, {
        String? token,
        Map<String, dynamic>? queryParameters,
      }) {
    final authToken = token ?? _preferences.token;

    return dio.get<T>(
      '${ApiConstants.baseUrl}$path',
      queryParameters: queryParameters,
      options: Options(
        headers: ApiHeaders.getHeaders(
          token: authToken,
        ),
      ),
    );
  }

  Future<Response<T>> post<T>(
      String path, {
        String? token,
        dynamic data,
      }) {
    final authToken = token ?? _preferences.token;

    return dio.post<T>(
      '${ApiConstants.baseUrl}$path',
      data: data,
      options: Options(
        headers: ApiHeaders.getHeaders(
          token: authToken,
        ),
      ),
    );
  }
}