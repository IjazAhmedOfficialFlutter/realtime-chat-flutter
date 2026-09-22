
import '../../model/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel?> getCurrentUser();

  Future<void> logout();

  bool get isLoggedIn;
}