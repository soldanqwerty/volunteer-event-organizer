import 'package:flutter/material.dart';

import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../home/home_screen.dart';
import 'registration_screen.dart';
import 'password_recovery_screen.dart';

/// Login screen, matching mockup S-02.
///
/// Per the assignment's Example #1: pressing "Увійти" simply navigates
/// to the home screen as if login succeeded — no real validation or
/// backend call is implemented yet.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _onLoginPressed() {
    // Hardcoded "successful login" — no real auth call yet.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Вхід', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Пароль',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(label: 'Увійти', onPressed: _onLoginPressed),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PasswordRecoveryScreen(),
                      ),
                    );
                  },
                  child: const Text('Забули пароль?'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegistrationScreen(),
                      ),
                    );
                  },
                  child: const Text('Немає акаунту? Зареєструватися'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
