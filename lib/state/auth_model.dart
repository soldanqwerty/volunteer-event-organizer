import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../data/services/analytics_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Стан автентифікації застосунку (app state).
///
/// Слухає потік userChanges() і сповіщає віджети (notifyListeners), коли
/// користувач входить, виходить або змінює профіль. Екрани реєстрації,
/// входу та відновлення пароля викликають методи моделі й показують
/// стан завантаження через [isLoading] та помилку через [errorMessage].
class AuthModel extends ChangeNotifier {
  AuthModel(this._repository) {
    _subscription = _repository.userChanges().listen(_onUserChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _onUserChanged(User? user) {
    _user = user;
    _status =
        user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  /// FR-02. Повертає true, якщо вхід успішний.
  Future<bool> signIn({required String email, required String password}) {
    return _run(() async {
      await _repository.signIn(email: email, password: password);
      AnalyticsService.logLogin();
    });
  }

  /// FR-01.
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return _run(() async {
      await _repository.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      AnalyticsService.logSignUp();
    });
  }

  /// FR-03.
  Future<bool> sendPasswordReset({required String email}) {
    return _run(() async {
      await _repository.sendPasswordReset(email: email);
      AnalyticsService.logPasswordResetRequested();
    });
  }

  /// FR-04. Вихід: потік userChanges() поверне null, і AuthGate
  /// автоматично покаже екран входу.
  Future<bool> signOut() => _run(_repository.signOut);

  /// Спільна обгортка для асинхронних дій: блокує повторний виклик,
  /// вмикає стан завантаження та перехоплює помилку.
  Future<bool> _run(Future<void> Function() action) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
