import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_sidebar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/repositories/auth_repository.dart';
import 'avatar_picker_dialog.dart';

/// Екран профілю (макет S-11, вимоги FR-04, FR-05, FR-06).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository();
  late final Stream<User?> _userStream = _authRepository.userChanges();

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

  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _isUpdatingPhoto = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Поля заповнюються один раз, щоб перебудови екрана не стирали
    // те, що користувач уже почав редагувати.
    final user = _authRepository.currentUser;
    final nameParts = (user?.displayName ?? '').trim().split(RegExp(r'\s+'));
    _firstNameController = TextEditingController(text: nameParts.first);
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// FR-04. Збереження імені та прізвища.
  Future<void> _onSaveChangesPressed() async {
    if (_isSavingProfile) return;
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    try {
      await _authRepository.updateDisplayName(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      if (mounted) _showMessage('Профіль оновлено');
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  /// FR-05. Зміна пароля з повторною автентифікацією.
  Future<void> _onChangePasswordPressed() async {
    if (_isChangingPassword) return;
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);
    try {
      await _authRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      // Прибирає підказки «Введіть пароль» під щойно очищеними полями.
      _passwordFormKey.currentState!.reset();
      _showMessage('Пароль успішно змінено');
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  /// FR-06. Вибір фото профілю з готових або за власним посиланням.
  Future<void> _onChangePhotoPressed(User? user) async {
    if (_isUpdatingPhoto) return;

    final choice = await showDialog<AvatarChoice>(
      context: context,
      builder: (_) => AvatarPickerDialog(
        currentUrl: user?.photoURL,
        initials: UserAvatar.initialsFrom(user?.displayName),
      ),
    );
    if (choice == null || !mounted) return;

    setState(() => _isUpdatingPhoto = true);
    try {
      await _authRepository.updatePhotoUrl(choice.url);
      if (mounted) {
        _showMessage(choice.url == null ? 'Фото видалено' : 'Фото оновлено');
      }
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  /// FR-04. Вихід: AuthGate сам покаже екран входу.
  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoggingOut = true);

    try {
      await _authRepository.signOut();
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('Ви вийшли з облікового запису')),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _onNavDestinationSelected(int index) {
    switch (index) {
      case 0:
        // Профіль відкрито поверх головної — просто закриваємо його.
        Navigator.of(context).pop();
        break;
      case 3:
        break;
      default:
        _showMessage('Цей розділ буде додано пізніше');
    }
  }

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
    return StreamBuilder<User?>(
      stream: _userStream,
      initialData: _authRepository.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          body: Row(
            children: [
              AppSidebar(
                selectedIndex: 3,
                onDestinationSelected: _onNavDestinationSelected,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SingleChildScrollView(
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
                            child: _buildSummaryCard(context, user),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildPersonalDataCard(context),
                                const SizedBox(height: 16),
                                _buildPasswordCard(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildSummaryCard(BuildContext context, User? user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = (user?.displayName ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(
                  photoUrl: user?.photoURL,
                  initials: UserAvatar.initialsFrom(user?.displayName),
                  radius: 40,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: _isUpdatingPhoto
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
                          onPressed: () => _onChangePhotoPressed(user),
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
              user?.email ?? '',
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
                color: colorScheme.primaryContainer.withOpacity(0.4),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _onLogoutPressed,
                icon: const Icon(Icons.logout),
                label: const Text('Вийти'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataCard(BuildContext context) {
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
                      enabled: !_isSavingProfile,
                      validator: (value) =>
                          Validators.name(value, emptyMessage: "Введіть ім'я"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Прізвище',
                      controller: _lastNameController,
                      enabled: !_isSavingProfile,
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
                    isLoading: _isSavingProfile,
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

  Widget _buildPasswordCard(BuildContext context) {
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
                enabled: !_isChangingPassword,
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
                      enabled: !_isChangingPassword,
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
                      enabled: !_isChangingPassword,
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
                    isLoading: _isChangingPassword,
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
