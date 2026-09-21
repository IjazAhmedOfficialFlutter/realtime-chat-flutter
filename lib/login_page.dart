import 'package:flutter/material.dart';
import 'package:realtime_chat_flutter/pages/user_list_page.dart';

import 'core/auth_services.dart';
import 'generated/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(
    text: 'ijaz@test.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '123456',
  );
  final AuthService _authService = AuthService();
  bool _loading = false;

  // Future<void> _login() async {
  //
  //   Navigator.pushReplacement(context, UserListPage(   locale: _locale,
  //     onLocaleChanged: _changeLocale,)
  //   // if (_loading) {

  //   //   return;
  //   // }
  //   //
  //   // final localizations = AppLocalizations.of(context)!;
  //   //
  //   // setState(() {
  //   //   _loading = true;
  //   // });
  //   //
  //   // try {
  //   //   debugPrint('BUTTON PRESSED');
  //   //   await _authService.testSocket();
  //   //
  //   //   if (!mounted) {
  //   //     return;
  //   //   }
  //   //
  //   //   ScaffoldMessenger.of(context)
  //   //       .showSnackBar(SnackBar(content: Text(localizations.good_morning)));
  //   // } catch (e) {
  //   //   debugPrint('SOCKET TEST ERROR: $e');
  //   //
  //   //   if (!mounted) {
  //   //     return;
  //   //   }
  //   //
  //   //   ScaffoldMessenger.of(context)
  //   //       .showSnackBar(SnackBar(content: Text(e.toString())));
  //   // } finally {
  //   //   if (mounted) {
  //   //     setState(() {
  //   //       _loading = false;
  //   //     });
  //   //   }
  //   // }
  // }

  Future<void> _login() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UserListPage(
          locale: widget.locale,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.login),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: widget.locale,
                icon: const Icon(Icons.language),
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('EN')),
                  DropdownMenuItem(value: Locale('ur'), child: Text('اردو')),
                  DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                  DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                  DropdownMenuItem(value: Locale('bn'), child: Text('বাংলা')),
                ],
                onChanged: (locale) {
                  if (locale != null) {
                    widget.onLocaleChanged(locale);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: localizations.email),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: localizations.password),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(localizations.test_connection),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
