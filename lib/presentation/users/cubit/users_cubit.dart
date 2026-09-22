import 'package:flutter_bloc/flutter_bloc.dart';

import '../repo/user_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final UserRepository _repository;

  UsersCubit(this._repository) : super(const UsersState());

  Future<void> loadUsers() async {
    emit(
      state.copyWith(
        status: UsersStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final users = await _repository.getUsers();

      emit(
        state.copyWith(
          status: UsersStatus.success,
          users: users,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UsersStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}