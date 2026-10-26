import 'package:firebase_auth/firebase_auth.dart';

/// Помилка автентифікації з уже перекладеним, зрозумілим користувачу
/// повідомленням. Екрани показують [message] у SnackBar або біля поля.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Єдине місце в застосунку, яке напряму працює з Firebase Authentication.
/// Екрани викликають методи цього класу й нічого не знають про Firebase.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance {
    // Листи Firebase (відновлення пароля) надсилатимуться українською.
    _auth.setLanguageCode('uk');
  }

  final FirebaseAuth _auth;

  /// Потік стану входу: null — ніхто не увійшов, User — поточний користувач.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Як authStateChanges, але також сповіщає про зміну імені чи фото.
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// FR-01. Реєстрація: створює акаунт і зберігає ім'я та прізвище.
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(
        '${firstName.trim()} ${lastName.trim()}',
      );
      await credential.user?.reload();
    });
  }

  /// FR-02. Вхід за email і паролем.
  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  /// FR-03. Надсилає лист із посиланням для встановлення нового пароля.
  Future<void> sendPasswordReset({required String email}) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  /// FR-04. Вихід із системи.
  Future<void> signOut() => _guard(() => _auth.signOut());

  /// FR-04. Зміна імені та прізвища.
  Future<void> updateDisplayName({
    required String firstName,
    required String lastName,
  }) {
    return _guard(() async {
      final user = _requireUser();
      await user.updateDisplayName('${firstName.trim()} ${lastName.trim()}');
      await user.reload();
    });
  }

  /// FR-06. Зберігає посилання на фото профілю (сам файл не завантажується).
  Future<void> updatePhotoUrl(String? url) {
    return _guard(() async {
      final user = _requireUser();
      await user.updatePhotoURL(url);
      await user.reload();
    });
  }

  /// FR-05. Зміна пароля з повторною автентифікацією поточним паролем.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard(() async {
      final user = _requireUser();
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }, isPasswordChange: true);
  }

  // ---------------------------------------------------------------------------

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Сеанс завершено. Увійдіть знову.');
    }
    return user;
  }

  /// Виконує дію і перетворює будь-яку помилку Firebase на [AuthException].
  Future<T> _guard<T>(
    Future<T> Function() action, {
    bool isPasswordChange = false,
  }) async {
    try {
      return await action();
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code, isPasswordChange));
    } catch (_) {
      throw const AuthException('Сталася невідома помилка. Спробуйте ще раз.');
    }
  }

  String _messageFor(String code, bool isPasswordChange) {
    // Під час зміни пароля «неправильні дані» стосуються поточного пароля.
    if (isPasswordChange &&
        (code == 'invalid-credential' || code == 'wrong-password')) {
      return 'Поточний пароль введено неправильно.';
    }

    switch (code) {
      case 'invalid-email':
        return 'Некоректний формат електронної пошти.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Не вдалося увійти. Перевірте email і пароль.';
      case 'user-disabled':
        return 'Цей обліковий запис заблоковано.';
      case 'email-already-in-use':
        return 'Обліковий запис із цією поштою вже існує.';
      case 'weak-password':
        return 'Пароль занадто простий. Використайте щонайменше 8 символів.';
      case 'requires-recent-login':
        return 'З міркувань безпеки увійдіть знову й повторіть дію.';
      case 'too-many-requests':
        return 'Забагато спроб. Спробуйте пізніше.';
      case 'network-request-failed':
        return 'Немає з\'єднання з інтернетом.';
      case 'operation-not-allowed':
        return 'Цей спосіб входу вимкнено в налаштуваннях Firebase.';
      default:
        return 'Сталася помилка ($code). Спробуйте ще раз.';
    }
  }
}
