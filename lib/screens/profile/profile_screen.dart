import 'package:flutter/material.dart';

import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../auth/login_screen.dart';

/// Profile screen, matching mockup S-11.
///
/// Uses hardcoded user data (per the assignment's Example #2) instead
/// of a real backend. "Save changes" and "Change password" don't
/// persist anything yet — this is UI-only, without business logic.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameController = TextEditingController(text: 'Ігор');
  final _lastNameController = TextEditingController(text: 'Катеринюк');
  final _phoneController = TextEditingController(text: '+380');

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Hardcoded, read-only — matches the assignment's static-data example.
  static const String _email = 'igor@example.com';

  void _onSaveChangesPressed() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Профіль оновлено')));
  }

  void _onChangePasswordPressed() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Пароль змінено')));
  }

  void _onLogoutPressed() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 24),
                AppTextField(label: 'Ім\'я', controller: _firstNameController),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Прізвище',
                  controller: _lastNameController,
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Телефон', controller: _phoneController),
                const SizedBox(height: 16),
                Text(
                  'Email: $_email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Зберегти зміни',
                  onPressed: _onSaveChangesPressed,
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Змінити пароль',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Поточний пароль',
                  controller: _currentPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Новий пароль',
                  controller: _newPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Підтвердження',
                  controller: _confirmPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Змінити',
                  onPressed: _onChangePasswordPressed,
                ),

                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _onLogoutPressed,
                  icon: const Icon(Icons.logout),
                  label: const Text('Вийти'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
