import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth_services.dart';
import 'autth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService)
      : super(const AuthInitial());
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      final user = await _authService.login(
        email,
        password,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
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

    try {
      final user = await _authService.register(
        name,
        email,
        password,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(
        AuthFailure(
          _messageFromError(e),
        ),
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();

    emit(const AuthUnauthenticated());
  }

  String _messageFromError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}