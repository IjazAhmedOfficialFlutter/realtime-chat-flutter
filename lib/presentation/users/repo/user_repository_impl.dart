

import 'package:realtime_chat_flutter/presentation/users/repo/user_repository.dart';

import '../../../core/api/user_api.dart';
import '../../../model/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserApi _userApi;

  UserRepositoryImpl(this._userApi);

  @override
  Future<List<UserModel>> getUsers() {
    return _userApi.getUsers();
  }
}