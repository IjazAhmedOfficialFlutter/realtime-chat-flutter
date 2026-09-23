import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repo/user_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final UserRepository _repository;

  UsersCubit(this._repository) : super(const UsersState());

  Future<void> loadUsers({
    bool showLoading = true,
  }) async {
    if (showLoading) {
      emit(
        state.copyWith(
          status: UsersStatus.loading,
          errorMessage: null,
        ),
      );
    }

    try {
      final users = await _repository.getUsers();

      debugPrint(
        'USERS LOADED: '
            '${users.map((user) => '${user.name}: ${user.unreadCount}').toList()}',
      );

      emit(
        state.copyWith(
          status: UsersStatus.success,
          users: users,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint(
        'LOAD USERS ERROR: $e',
      );

      if (state.users.isNotEmpty && !showLoading) {
        emit(
          state.copyWith(
            errorMessage: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UsersStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}