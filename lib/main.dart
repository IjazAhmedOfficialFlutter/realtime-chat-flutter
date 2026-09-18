import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'core/auth_services.dart';
import 'login_page.dart';
import 'notifications/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDVT3-apWzEZOJ9PWaO5h8wtxg2kNHkOik',
      appId: '1:103366416712:android:1428ed5f6cf60ac1f4bb7d',
      messagingSenderId: '103366416712',
      projectId: 'realchatapp-55cd7',
      storageBucket: 'realchatapp-55cd7.firebasestorage.app',
    ),
  );
  await FcmService().initialize();
  runApp(const RealtimeChatApp());
}

class RealtimeChatApp extends StatelessWidget {
  const RealtimeChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (_) => const LoginPage(),
        '/chat': (_) => const ChatPage(),
      },
      home: const StartupPage(),
    );
  }
}

class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  Future<Widget> _page() async {
    final auth = AuthService();

    if (await auth.isLoggedIn()) {
      return const ChatPage();
    }

    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _page(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data!;
      },
    );
  }
}
