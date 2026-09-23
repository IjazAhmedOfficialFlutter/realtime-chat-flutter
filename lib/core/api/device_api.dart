import 'api_client.dart';

class DeviceApi {
  final ApiClient _apiClient;

  DeviceApi(this._apiClient);

  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    await _apiClient.post(
      '/api/devices/register',
      data: {
        'fcmToken': fcmToken,
        'platform': platform,
      },
    );
  }
}