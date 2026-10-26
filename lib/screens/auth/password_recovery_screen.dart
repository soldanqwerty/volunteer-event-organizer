import 'package:flutter/material.dart';

import '../../data/services/analytics_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';

/// Екран відновлення пароля (макет S-03, вимога FR-03).
/// Надсилає лист із посиланням для встановлення нового пароля.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isSent = false;

  Future<void> _onSendPressed() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      await _authRepository.sendPasswordReset(email: _emailController.text);
      AnalyticsService.logPasswordResetRequested();
      if (mounted) setState(() => _isSent = true);
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
            child: _isSent ? _buildSentState(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Відновлення пароля', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Введіть email, вказаний під час реєстрації. '
            'Ми надішлемо посилання для встановлення нового пароля.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !_isLoading,
            validator: Validators.email,
            onFieldSubmitted: (_) => _onSendPressed(),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Надіслати посилання',
            isLoading: _isLoading,
            onPressed: _onSendPressed,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Повернутися до входу'),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text('Перевірте пошту', style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Якщо адресу ${_emailController.text.trim()} зареєстровано, '
          'лист із посиланням для відновлення пароля вже надіслано. '
          'Перевірте також папку «Спам».',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Повернутися до входу',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
