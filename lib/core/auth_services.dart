import '../data/repositories/auth_repository.dart';
import '../model/user_model.dart';

class AuthService {
  final AuthRepository _repository;

  AuthService(this._repository);

  bool get isLoggedIn => _repository.isLoggedIn;

  Future<UserModel> login(
      String email,
      String password,
      ) {
    return _repository.login(
      email: email,
      password: password,
    );
  }

  Future<UserModel> register(
      String name,
      String email,
      String password,
      ) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<UserModel?> getCurrentUser() {
    return _repository.getCurrentUser();
  }

  Future<void> logout() {
    return _repository.logout();
  }
}