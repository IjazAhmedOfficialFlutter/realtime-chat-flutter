import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'core/auth_services.dart';
import 'login_page.dart';

void main() {
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.data!;
      },
    );
  }
}