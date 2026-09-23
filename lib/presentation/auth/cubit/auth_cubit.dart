// import 'package:flutter/cupertino.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../../../core/api/device_api.dart';
// import '../../../core/auth_services.dart';
// import '../../../data/services/firebase_messaging_service.dart';
// import 'autth_state.dart';
//
// class AuthCubit extends Cubit<AuthState> {
//   final AuthService _authService;
//   final DeviceApi _deviceApi;
//   final FirebaseMessagingService _firebaseMessagingService;
//
//   AuthCubit(this._authService, this._deviceApi, this._firebaseMessagingService)
//     : super(const AuthInitial());
//
//   Future<void> login({required String email, required String password}) async {
//     emit(const AuthLoading());
//
//     try {
//       final user = await _authService.login(email, password);
//
//       await _registerFcmToken();
//
//       emit(AuthAuthenticated(user));
//     } catch (e) {
//       emit(AuthFailure(_messageFromError(e)));
//     }
//   }
//
//   Future<void> register({
//     required String name,
//     required String email,
//     required String password,
//   }) async {
//     emit(const AuthLoading());
//
//     try {
//       final user = await _authService.register(name, email, password);
//
//       await _registerFcmToken();
//
//       emit(AuthAuthenticated(user));
//     } catch (e) {
//       emit(AuthFailure(_messageFromError(e)));
//     }
//   }
//
//   Future<void> logout() async {
//     await _authService.logout();
//
//     emit(const AuthUnauthenticated());
//   }
//
//   Future<void> _registerFcmToken() async {
//     try {
//       _firebaseMessagingService.onTokenReceived =
//           (token) async {
//         debugPrint(
//           'REGISTERING FCM DEVICE: $token',
//         );
//
//         await _deviceApi.registerDevice(
//           fcmToken: token,
//           platform: 'android',
//         );
//       };
//
//       await _firebaseMessagingService.initialize();
//     } catch (e) {
//       debugPrint(
//         'FCM DEVICE REGISTRATION ERROR: $e',
//       );
//     }
//   }
//
//   String _messageFromError(Object error) {
//     final message = error.toString();
//
//     if (message.startsWith('Exception: ')) {
//       return message.substring(11);
//     }
//
//     return message;
//   }
// }
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/device_api.dart';
import '../../../core/auth_services.dart';
import '../../../data/services/firebase_messaging_service.dart';
import 'autth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final DeviceApi _deviceApi;
  final FirebaseMessagingService _firebaseMessagingService;

  AuthCubit(
      this._authService,
      this._deviceApi,
      this._firebaseMessagingService,
      ) : super(const AuthInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    debugPrint('LOGIN: starting');

    try {
      final user = await _authService.login(
        email,
        password,
      );

      debugPrint(
        'LOGIN: success userId=${user.id}',
      );

      await _registerFcmToken();

      emit(AuthAuthenticated(user));
    } catch (e) {
      debugPrint(
        'LOGIN ERROR: $e',
      );

      emit(
        AuthFailure(
          _messageFromError(e),
        ),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    debugPrint('REGISTER: starting');

    try {
      final user = await _authService.register(
        name,
        email,
        password,
      );

      debugPrint(
        'REGISTER: success userId=${user.id}',
      );

      await _registerFcmToken();

      emit(AuthAuthenticated(user));
    } catch (e) {
      debugPrint(
        'REGISTER ERROR: $e',
      );

      emit(
        AuthFailure(
          _messageFromError(e),
        ),
      );
    }
  }

  Future<void> logout() async {
    debugPrint('LOGOUT: starting');

    await _authService.logout();

    debugPrint('LOGOUT: success');

    emit(const AuthUnauthenticated());
  }

  Future<void> _registerFcmToken() async {
    try {
      _firebaseMessagingService.onTokenReceived =
          (token) async {
        debugPrint(
          'FCM DEVICE REGISTER: token received',
        );

        debugPrint(
          'FCM DEVICE REGISTER: calling API',
        );

        await _deviceApi.registerDevice(
          fcmToken: token,
          platform: 'android',
        );

        debugPrint(
          'FCM DEVICE REGISTER: API success',
        );
      };

      debugPrint(
        'FCM DEVICE REGISTER: initializing',
      );

      await _firebaseMessagingService.initialize();

      debugPrint(
        'FCM DEVICE REGISTER: initialization complete',
      );
    } catch (e) {
      debugPrint(
        'FCM DEVICE REGISTER ERROR: $e',
      );
    }
  }

  String _messageFromError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}