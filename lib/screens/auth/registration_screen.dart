import 'package:flutter/material.dart';

import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../home/home_screen.dart';

/// Registration screen, matching mockup S-01.
///
/// Per the assignment's Example #1: pressing "Зареєструватися" simply
/// navigates to the home screen as if registration succeeded — no real
/// validation or backend call is implemented yet.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _onRegisterPressed() {
    // Hardcoded "successful registration" — no real backend call yet.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Реєстрація',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                AppTextField(label: 'Ім\'я', controller: _firstNameController),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Прізвище',
                  controller: _lastNameController,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Підтвердження пароля',
                  controller: _confirmPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Зареєструватися',
                  onPressed: _onRegisterPressed,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Вже маєте акаунт? Увійти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
