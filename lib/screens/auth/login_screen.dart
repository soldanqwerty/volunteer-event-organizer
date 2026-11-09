import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../state/auth_model.dart';
import 'password_recovery_screen.dart';
import 'registration_screen.dart';

/// Екран входу (макет S-02, вимога FR-02).
/// Після успішного входу AuthGate автоматично показує головний екран.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  /// FR-02. Після успішного входу AuthModel змінює статус, і AuthGate
  /// сам показує основну оболонку — переходити вручну не потрібно.
  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthModel>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!ok && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Не вдалося увійти')),
      );
    }
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Кнопка й поля блокуються, поки AuthModel виконує вхід.
    final isLoading = context.select<AuthModel, bool>((m) => m.isLoading);

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
                      'Вхід',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !isLoading,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Пароль',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !isLoading,
                      validator: Validators.loginPassword,
                      onFieldSubmitted: (_) => _onLoginPressed(),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Увійти',
                      isLoading: isLoading,
                      onPressed: _onLoginPressed,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => _openScreen(const PasswordRecoveryScreen()),
                      child: const Text('Забули пароль?'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => _openScreen(const RegistrationScreen()),
                      child: const Text('Немає акаунту? Зареєструватися'),
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
