import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth_services.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/firebase_messaging_service.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/users/repo/user_repository.dart';
import '../../presentation/users/repo/user_repository_impl.dart';
import '../../realtime/signalr_service.dart';
import '../api/auth_api.dart';

import '../../presentation/users/cubit/users_cubit.dart';
import '../api/user_api.dart';
final GetIt locator = GetIt.instance;

SharedPreferences get preferences => locator<SharedPreferences>();

AppPreferences get appPreferences => locator<AppPreferences>();

Dio get dio => locator<Dio>();

ApiClient get apiClient => locator<ApiClient>();

AuthApi get authApi => locator<AuthApi>();
SignalRService get signalRService => locator<SignalRService>();
AuthRepository get authRepository => locator<AuthRepository>();

AuthService get authService => locator<AuthService>();
UserApi get userApi => locator<UserApi>();

UserRepository get userRepository => locator<UserRepository>();
FirebaseMessagingService get firebaseMessagingService =>
    locator<FirebaseMessagingService>();

Future<void> setupDependencies() async {
  final preferencesInstance = await SharedPreferences.getInstance();
  if (!locator.isRegistered<AuthCubit>()) {
    locator.registerFactory<AuthCubit>(
          () => AuthCubit(authService),
    );
  }
  if (!locator.isRegistered<SharedPreferences>()) {
    locator.registerLazySingleton<SharedPreferences>(
          () => preferencesInstance,
    );
  }

  if (!locator.isRegistered<AppPreferences>()) {
    locator.registerLazySingleton<AppPreferences>(
          () => AppPreferences(preferences),
    );
  }

  if (!locator.isRegistered<Dio>()) {
    locator.registerLazySingleton<Dio>(
          () => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      ),
    );
  }if (!locator.isRegistered<SignalRService>()) {
    locator.registerLazySingleton<SignalRService>(
          () => SignalRService(),
    );
  }

  if (!locator.isRegistered<UserApi>()) {
    locator.registerLazySingleton<UserApi>(
          () => UserApi(apiClient),
    );
  }

  if (!locator.isRegistered<UserRepository>()) {
    locator.registerLazySingleton<UserRepository>(
          () => UserRepositoryImpl(userApi),
    );
  }

  if (!locator.isRegistered<UsersCubit>()) {
    locator.registerFactory<UsersCubit>(
          () => UsersCubit(userRepository),
    );
  }

  if (!locator.isRegistered<ApiClient>()) {
    locator.registerLazySingleton<ApiClient>(
          () => ApiClient(
        dio,
        appPreferences,
      ),
    );
  }

  if (!locator.isRegistered<AuthApi>()) {
    locator.registerLazySingleton<AuthApi>(
          () => AuthApi(apiClient),
    );
  }

  if (!locator.isRegistered<AuthRepository>()) {
    locator.registerLazySingleton<AuthRepository>(
          () => AuthRepositoryImpl(
        authApi,
        appPreferences,
      ),
    );
  }

  if (!locator.isRegistered<AuthService>()) {
    locator.registerLazySingleton<AuthService>(
          () => AuthService(authRepository),
    );
  }

  if (!locator.isRegistered<FirebaseMessagingService>()) {
    locator.registerLazySingleton<FirebaseMessagingService>(
          () => FirebaseMessagingService(),
    );
  }
}