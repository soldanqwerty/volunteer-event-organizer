import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/user_avatar.dart';
import '../../state/auth_model.dart';
import '../../state/profile_model.dart';
import 'avatar_picker_dialog.dart';

/// Екран профілю (макет S-11, вимоги FR-04, FR-05, FR-06).
///
/// Дані профілю та стани збереження — у ProfileModel (Provider),
/// вихід — через AuthModel. Контролери полів залишаються ефемерним
/// станом цього екрана.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  // Заглушка: телефон зберігатиметься у Firestore (наступні лабораторні).
  final _phoneController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Поля заповнюються один раз, щоб перебудови екрана не стирали
    // те, що користувач уже почав редагувати.
    final profile = context.read<ProfileModel>();
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// FR-04. Збереження імені та прізвища.
  Future<void> _onSaveChangesPressed() async {
    if (!_profileFormKey.currentState!.validate()) return;

    final error = await context.read<ProfileModel>().updateName(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
        );
    if (mounted) _showMessage(error ?? 'Профіль оновлено');
  }

  /// FR-05. Зміна пароля з повторною автентифікацією.
  Future<void> _onChangePasswordPressed() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final error = await context.read<ProfileModel>().changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    // Прибирає підказки «Введіть пароль» під щойно очищеними полями.
    _passwordFormKey.currentState!.reset();
    _showMessage('Пароль успішно змінено');
  }

  /// FR-06. Вибір фото профілю з готових або за власним посиланням.
  Future<void> _onChangePhotoPressed(ProfileModel profile) async {
    if (profile.isUpdatingPhoto) return;

    final choice = await showDialog<AvatarChoice>(
      context: context,
      builder: (_) => AvatarPickerDialog(
        currentUrl: profile.photoUrl,
        initials: UserAvatar.initialsFrom(profile.displayName),
      ),
    );
    if (choice == null || !mounted) return;

    final error = await profile.updatePhoto(choice.url);
    if (mounted) {
      _showMessage(
        error ?? (choice.url == null ? 'Фото видалено' : 'Фото оновлено'),
      );
    }
  }

  /// FR-04. Вихід: AuthGate сам покаже екран входу, а SessionScope
  /// звільнить стан заходів і завдань.
  Future<void> _onLogoutPressed() async {
    final auth = context.read<AuthModel>();
    final ok = await auth.signOut();
    if (!ok && mounted) {
      _showMessage(auth.errorMessage ?? 'Не вдалося вийти');
    }
  }

  // ▼ Sentry: тестові помилки (лише в режимі розробки)

  /// Необроблена помилка — її автоматично перехоплює FlutterError.onError,
  /// який налаштовує SentryFlutter.init.
  void _throwUnhandledTestError() {
    throw StateError('Тестова необроблена помилка VolunteerHub (Sentry)');
  }

  /// Оброблена (нефатальна) помилка: застосунок працює далі,
  /// а помилка вручну передається в Sentry.
  Future<void> _sendHandledTestError() async {
    try {
      throw Exception('Тестова оброблена помилка VolunteerHub (Sentry)');
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
      if (mounted) _showMessage('Тестову помилку надіслано в Sentry');
    }
  }

  // ▲ Sentry

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // watch: екран оновлюється після зміни імені, фото чи стану
    // збереження в ProfileModel.
    final profile = context.watch<ProfileModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 260,
                child: _buildSummaryCard(context, profile),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildPersonalDataCard(context, profile),
                    const SizedBox(height: 16),
                    _buildPasswordCard(context, profile),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'МІЙ ПРОФІЛЬ',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          'Налаштування акаунту',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, ProfileModel profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = profile.displayName;
    final isLoggingOut = context.select<AuthModel, bool>((m) => m.isLoading);

    // Як на макеті S-11, кнопка «Вийти» розташована під карткою.
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    UserAvatar(
                      photoUrl: profile.photoUrl,
                      initials: UserAvatar.initialsFrom(profile.displayName),
                      radius: 40,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: profile.isUpdatingPhoto
                          ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Змінити фото',
                              icon: const Icon(Icons.camera_alt, size: 14),
                              color: colorScheme.onPrimary,
                              onPressed: () => _onChangePhotoPressed(profile),
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  displayName.isEmpty ? 'Без імені' : displayName,
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  profile.email,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Заглушка: статистика з'явиться після підключення Firestore.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Внесок цього місяця', style: textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '18 год',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoggingOut ? null : _onLogoutPressed,
            icon: const Icon(Icons.logout),
            label: const Text('Вийти'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
          ),
        ),
        // ▼ Sentry: тестові кнопки, видно лише в режимі розробки
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _sendHandledTestError,
            child: const Text('Тест Sentry: оброблена помилка'),
          ),
          TextButton(
            onPressed: _throwUnhandledTestError,
            child: const Text('Тест Sentry: необроблена помилка'),
          ),
        ],
        // ▲ Sentry
      ],
    );
  }

  Widget _buildPersonalDataCard(BuildContext context, ProfileModel profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardTitle(context, Icons.badge_outlined, 'Особисті дані'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: "Ім'я",
                      controller: _firstNameController,
                      enabled: !profile.isSavingName,
                      validator: (value) =>
                          Validators.name(value, emptyMessage: "Введіть ім'я"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Прізвище',
                      controller: _lastNameController,
                      enabled: !profile.isSavingName,
                      validator: (value) => Validators.name(
                        value,
                        emptyMessage: 'Введіть прізвище',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Телефон (буде додано пізніше)',
                      controller: _phoneController,
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 200,
                  child: AppPrimaryButton(
                    label: 'Зберегти зміни',
                    isLoading: profile.isSavingName,
                    onPressed: _onSaveChangesPressed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context, ProfileModel profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardTitle(context, Icons.lock_outline, 'Змінити пароль'),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Поточний пароль',
                controller: _currentPasswordController,
                obscureText: true,
                enabled: !profile.isChangingPassword,
                autofillHints: const [AutofillHints.password],
                validator: Validators.loginPassword,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Новий пароль',
                      controller: _newPasswordController,
                      obscureText: true,
                      enabled: !profile.isChangingPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) {
                        final error = Validators.newPassword(value);
                        if (error != null) return error;
                        if (value == _currentPasswordController.text) {
                          return 'Новий пароль має відрізнятися від поточного';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Підтвердження',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      enabled: !profile.isChangingPassword,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _newPasswordController.text,
                      ),
                      onFieldSubmitted: (_) => _onChangePasswordPressed(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 160,
                  child: AppPrimaryButton(
                    label: 'Змінити',
                    isLoading: profile.isChangingPassword,
                    onPressed: _onChangePasswordPressed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
