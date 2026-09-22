import 'package:equatable/equatable.dart';

import '../../../model/user_model.dart';


enum UsersStatus {
  initial,
  loading,
  success,
  failure,
}

class UsersState extends Equatable {
  final UsersStatus status;
  final List<UserModel> users;
  final String? errorMessage;

  const UsersState({
    this.status = UsersStatus.initial,
    this.users = const [],
    this.errorMessage,
  });

  UsersState copyWith({
    UsersStatus? status,
    List<UserModel>? users,
    String? errorMessage,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    errorMessage,
  ];
}