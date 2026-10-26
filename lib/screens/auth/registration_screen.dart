import 'package:flutter/material.dart';

import '../../data/services/analytics_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';

/// Екран реєстрації (макет S-01, вимога FR-01).
/// Після успішної реєстрації користувач автоматично входить у систему,
/// а AuthGate показує головний екран.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;

  Future<void> _onRegisterPressed() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);

    try {
      await _authRepository.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      AnalyticsService.logSignUp();
      messenger.showSnackBar(
        const SnackBar(content: Text('Обліковий запис створено. Вітаємо!')),
      );
      // Закриваємо екран реєстрації: під ним AuthGate уже показує Home.
      navigator.popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Реєстрація',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Ім\'я',
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      enabled: !_isLoading,
                      validator: (value) =>
                          Validators.name(value, emptyMessage: 'Введіть ім\'я'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Прізвище',
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      enabled: !_isLoading,
                      validator: (value) => Validators.name(
                        value,
                        emptyMessage: 'Введіть прізвище',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !_isLoading,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Пароль',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      enabled: !_isLoading,
                      validator: Validators.newPassword,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Підтвердження пароля',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _onRegisterPressed(),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Зареєструватися',
                      isLoading: _isLoading,
                      onPressed: _onRegisterPressed,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Вже маєте акаунт? Увійти'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
