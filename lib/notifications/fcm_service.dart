import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    final token = await _messaging.getToken();

    debugPrint('FCM TOKEN: $token');

    _messaging.onTokenRefresh.listen(
      (token) {
        debugPrint('FCM TOKEN REFRESHED: $token');
      },
      onError: (error) {
        debugPrint('FCM token refresh error: $error');
      },
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM FOREGROUND MESSAGE: ${message.data}');

      debugPrint(
        'FCM FOREGROUND TITLE: '
        '${message.notification?.title}',
      );

      debugPrint(
        'FCM FOREGROUND BODY: '
        '${message.notification?.body}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM OPENED: ${message.data}');
    });

    return token;
  }
}
