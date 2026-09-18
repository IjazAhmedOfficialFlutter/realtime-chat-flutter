import 'package:flutter/material.dart';

import 'core/auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController =
  TextEditingController(
    text: 'ijaz@test.com',
  );

  final TextEditingController _passwordController =
  TextEditingController(
    text: '123456',
  );

  final AuthService _authService = AuthService();

  bool _loading = false;

  Future<void> _login() async {
    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      debugPrint('BUTTON PRESSED');

      await _authService.testSocket();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socket connection successful'),
        ),
      );
    } catch (e) {
      debugPrint('SOCKET TEST ERROR: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType:
              TextInputType.emailAddress,
              decoration:
              const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration:
              const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Test Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}