import 'package:go_router/go_router.dart';

import '../core/auth_services.dart';
import '../core/di/injection.dart';
import '../data/services/firebase_messaging_service.dart';
import '../model/user_model.dart';
import '../presentation/auth/pages/login_page.dart';
import '../presentation/auth/pages/signup_page.dart';
import '../presentation/chat/pages/chat_page.dart';
import '../presentation/home/home_page.dart';
import '../presentation/users/pages/users_page.dart';
import '../presentation/users/repo/user_repository.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final authService = locator<AuthService>();
    final isLoggedIn = authService.isLoggedIn;

    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    if (isLoggedIn && isAuthRoute) {
      return '/users';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/users',
      name: 'users',
      builder: (context, state) => const UsersPage(),
    ),
    GoRoute(
      path: '/chat/:userId',
      name: 'chat',
      builder: (context, state) {
        final receiver = state.extra as UserModel?;

        if (receiver == null) {
          return const UsersPage();
        }

        return ChatPage(receiver: receiver);
      },
    ),
  ],
);

Future<void> handleFcmNotificationTap(Map<String, dynamic> data) async {
  final type = data['type']?.toString();

  if (type != 'chat') {
    return;
  }

  final senderId = int.tryParse(data['senderId']?.toString() ?? '');

  if (senderId == null) {
    return;
  }

  try {
    final repository = locator<UserRepository>();
    final users = await repository.getUsers();

    UserModel? receiver;

    for (final user in users) {
      if (user.id == senderId) {
        receiver = user;
        break;
      }
    }

    if (receiver == null) {
      return;
    }

    appRouter.push('/chat/$senderId', extra: receiver);
  } catch (e) {
    print('FCM CHAT NAVIGATION ERROR: $e');
  }
}

void initializeFcmNotificationNavigation() {
  final firebaseMessagingService = locator<FirebaseMessagingService>();

  firebaseMessagingService.onNotificationTap = handleFcmNotificationTap;
}
