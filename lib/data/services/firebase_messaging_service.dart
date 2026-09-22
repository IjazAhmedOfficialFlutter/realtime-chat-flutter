import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM BACKGROUND MESSAGE: ${message.messageId}');
  debugPrint('FCM BACKGROUND DATA: ${message.data}');
}

typedef FcmNotificationTapCallback = Future<void> Function(
    Map<String, dynamic> data,
    );

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  bool _initialized = false;

  FcmNotificationTapCallback? onNotificationTap;

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await _initializeLocalNotifications();
    await _requestPermission();

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    await _loadToken();

    _listenForTokenRefresh();
    _listenForForegroundMessages();
    _listenForNotificationOpened();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'LOCAL NOTIFICATION TAPPED: ${response.payload}',
        );
      },
    );

    final androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'FCM AUTHORIZATION: ${settings.authorizationStatus}',
    );
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();

      debugPrint('FCM TOKEN: $token');

      return token;
    } catch (e) {
      debugPrint('FCM TOKEN ERROR: $e');

      return null;
    }
  }

  Future<void> _loadToken() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      _handleToken(token);
    }
  }

  void _listenForTokenRefresh() {
    _tokenSubscription = _messaging.onTokenRefresh.listen(
          (token) {
        debugPrint('FCM TOKEN REFRESHED: $token');

        _handleToken(token);
      },
    );
  }

  void _listenForForegroundMessages() {
    _messageSubscription = FirebaseMessaging.onMessage.listen(
          (message) async {
        debugPrint(
          'FCM FOREGROUND MESSAGE: ${message.messageId}',
        );

        debugPrint(
          'FCM FOREGROUND DATA: ${message.data}',
        );

        final notification = message.notification;

        if (notification == null) {
          return;
        }

        debugPrint(
          'FCM TITLE: ${notification.title}',
        );

        debugPrint(
          'FCM BODY: ${notification.body}',
        );

        await _showForegroundNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: message.data,
        );
      },
    );
  }

  Future<void> _showForegroundNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload.toString(),
    );
  }

  void _listenForNotificationOpened() {
    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
              (message) {
            debugPrint(
              'FCM NOTIFICATION OPENED: ${message.messageId}',
            );

            debugPrint(
              'FCM OPEN DATA: ${message.data}',
            );

            onNotificationTap?.call(
              message.data,
            );
          },
        );
  }

  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();

    if (message == null) {
      return;
    }

    debugPrint(
      'FCM INITIAL MESSAGE: ${message.messageId}',
    );

    debugPrint(
      'FCM INITIAL DATA: ${message.data}',
    );

    onNotificationTap?.call(
      message.data,
    );
  }

  void _handleToken(String token) {
    debugPrint(
      'SEND FCM TOKEN TO BACKEND: $token',
    );
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}


// class FirebaseMessagingService {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();
//
//   StreamSubscription<RemoteMessage>? _messageSubscription;
//   StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
//   StreamSubscription<String>? _tokenSubscription;
//
//   bool _initialized = false;
//
//   static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
//     'high_importance_channel',
//     'High Importance Notifications',
//     description: 'Used for important notifications.',
//     importance: Importance.high,
//     playSound: true,
//   );
//
//   Future<void> initialize() async {
//     if (_initialized) {
//       return;
//     }
//
//     _initialized = true;
//
//     await _initializeLocalNotifications();
//     await _requestPermission();
//
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//
//     await _loadToken();
//
//     _listenForTokenRefresh();
//     _listenForForegroundMessages();
//     _listenForNotificationOpened();
//   }
//
//   Future<void> _initializeLocalNotifications() async {
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );
//
//     const settings = InitializationSettings(android: androidSettings);
//
//     await _localNotifications.initialize(
//       settings,
//       onDidReceiveNotificationResponse: _handleNotificationResponse,
//     );
//
//     final androidPlugin = _localNotifications
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >();
//
//     await androidPlugin?.createNotificationChannel(_channel);
//     await androidPlugin?.requestNotificationsPermission();
//   }
//
//   void _handleNotificationResponse(NotificationResponse response) {
//     debugPrint('LOCAL NOTIFICATION TAPPED: ${response.payload}');
//   }
//
//   Future<void> _requestPermission() async {
//     final settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       provisional: false,
//     );
//
//     debugPrint('FCM AUTHORIZATION: ${settings.authorizationStatus}');
//   }
//
//   Future<String?> getToken() async {
//     try {
//       final token = await _messaging.getToken();
//
//       debugPrint('FCM TOKEN: $token');
//
//       return token;
//     } catch (e) {
//       debugPrint('FCM TOKEN ERROR: $e');
//
//       return null;
//     }
//   }
//
//   Future<void> _loadToken() async {
//     final token = await getToken();
//
//     if (token != null && token.isNotEmpty) {
//       _handleToken(token);
//     }
//   }
//
//   void _listenForTokenRefresh() {
//     _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
//       debugPrint('FCM TOKEN REFRESHED: $token');
//
//       _handleToken(token);
//     });
//   }
//
//   void _listenForForegroundMessages() {
//     _messageSubscription = FirebaseMessaging.onMessage.listen((message) async {
//       debugPrint('FCM FOREGROUND MESSAGE: ${message.messageId}');
//
//       debugPrint('FCM FOREGROUND DATA: ${message.data}');
//
//       final notification = message.notification;
//
//       if (notification == null) {
//         return;
//       }
//
//       debugPrint('FCM TITLE: ${notification.title}');
//
//       debugPrint('FCM BODY: ${notification.body}');
//
//       await _showForegroundNotification(
//         title: notification.title ?? '',
//         body: notification.body ?? '',
//         payload: message.data,
//       );
//     });
//   }
//
//   Future<void> _showForegroundNotification({
//     required String title,
//     required String body,
//     required Map<String, dynamic> payload,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       channelDescription: 'Used for important notifications.',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//     );
//
//     const details = NotificationDetails(android: androidDetails);
//
//     await _localNotifications.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title,
//       body,
//       details,
//       payload: payload.toString(),
//     );
//   }
//
//   void _listenForNotificationOpened() {
//     _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
//       message,
//     ) {
//       debugPrint('FCM NOTIFICATION OPENED: ${message.messageId}');
//
//       debugPrint('FCM OPEN DATA: ${message.data}');
//     });
//   }
//
//   Future<void> handleInitialMessage() async {
//     final message = await _messaging.getInitialMessage();
//
//     if (message == null) {
//       return;
//     }
//
//     debugPrint('FCM INITIAL MESSAGE: ${message.messageId}');
//
//     debugPrint('FCM INITIAL DATA: ${message.data}');
//   }
//
//   void _handleToken(String token) {
//     debugPrint('SEND FCM TOKEN TO BACKEND: $token');
//   }
//
//   Future<void> dispose() async {
//     await _messageSubscription?.cancel();
//     await _messageOpenedSubscription?.cancel();
//     await _tokenSubscription?.cancel();
//   }
// }
