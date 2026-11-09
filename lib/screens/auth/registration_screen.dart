import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../state/auth_model.dart';

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
  /// Стан завантаження береться з AuthModel; select перебудовує екран
  /// лише тоді, коли змінюється саме isLoading. Викликається під час build.
  bool get _isLoading => context.select<AuthModel, bool>((m) => m.isLoading);

  /// FR-01. Після реєстрації користувач автоматично входить, AuthModel
  /// змінює статус, і застосунок сам переходить до основної оболонки.
  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthModel>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
    );
    if (!ok && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Не вдалося зареєструватися')),
      );
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
