import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../data/services/analytics_service.dart';

/// Стан профілю: завантаження даних користувача та їх редагування
/// (FR-04, FR-05, FR-06).
///
/// Для кожної дії є окремий прапорець завантаження, бо на екрані профілю
/// три незалежні кнопки: «Зберегти зміни», «Змінити пароль» і фото.
/// Методи повертають null при успіху або текст помилки.
class ProfileModel extends ChangeNotifier {
  ProfileModel(this._repository) : _user = _repository.currentUser {
    _subscription = _repository.userChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  User? _user;
  bool _isSavingName = false;
  bool _isChangingPassword = false;
  bool _isUpdatingPhoto = false;

  User? get user => _user;
  bool get isSavingName => _isSavingName;
  bool get isChangingPassword => _isChangingPassword;
  bool get isUpdatingPhoto => _isUpdatingPhoto;

  String get displayName => (_user?.displayName ?? '').trim();
  String get email => _user?.email ?? '';
  String? get photoUrl => _user?.photoURL;

  String get firstName {
    final parts = displayName.split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  String get lastName {
    final parts = displayName.split(RegExp(r'\s+'));
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  Future<String?> updateName({
    required String firstName,
    required String lastName,
  }) async {
    if (_isSavingName) return null;
    _isSavingName = true;
    notifyListeners();
    try {
      await _repository.updateDisplayName(
        firstName: firstName,
        lastName: lastName,
      );
      AnalyticsService.logProfileUpdated();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      _isSavingName = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_isChangingPassword) return null;
    _isChangingPassword = true;
    notifyListeners();
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      AnalyticsService.logPasswordChanged();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  /// [url] == null — видалити фото.
  Future<String?> updatePhoto(String? url) async {
    if (_isUpdatingPhoto) return null;
    _isUpdatingPhoto = true;
    notifyListeners();
    try {
      await _repository.updatePhotoUrl(url);
      AnalyticsService.logAvatarChanged(
        source: url == null
            ? 'removed'
            : url.contains('dicebear')
                ? 'preset'
                : 'custom',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      _isUpdatingPhoto = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
