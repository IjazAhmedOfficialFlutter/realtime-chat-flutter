import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app_router.dart';
import 'core/di/injection.dart';
import 'data/services/firebase_messaging_service.dart';
import 'presentation/auth/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await setupDependencies();

  final firebaseMessagingService = locator<FirebaseMessagingService>();

  initializeFcmNotificationNavigation();

  await firebaseMessagingService.initialize();

  runApp(
    BlocProvider(
      create: (_) => locator<AuthCubit>(),
      child: const RealtimeChatApp(),
    ),
  );
}

class RealtimeChatApp extends StatefulWidget {
  const RealtimeChatApp({super.key});

  @override
  State<RealtimeChatApp> createState() => _RealtimeChatAppState();
}

class _RealtimeChatAppState extends State<RealtimeChatApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator<FirebaseMessagingService>().handleInitialMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Realtime Chat',
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
