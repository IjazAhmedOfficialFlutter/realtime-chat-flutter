class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'http://192.168.110.180:5082';

  static const String login =
      '/api/auth/login';

  static const String register =
      '/api/auth/register';

  static const String me =
      '/api/user/me';

  static const String users =
      '/api/users';
  static const String messages =
      '/api/messages';

  static const String chatHub =
      '$baseUrl/hubs/chat';
}