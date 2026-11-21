import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/storage_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/analytics_service.dart';

/// Стан профілю: завантаження даних користувача та їх редагування
/// (FR-04, FR-05, FR-06).
///
/// Для кожної дії є окремий прапорець завантаження, бо на екрані профілю
/// три незалежні кнопки: «Зберегти зміни», «Змінити пароль» і фото.
/// Методи повертають null при успіху або текст помилки.
class ProfileModel extends ChangeNotifier {
  ProfileModel(this._repository, {this._users, this._storage})
      : _user = _repository.currentUser {
    _subscription = _repository.userChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;

  /// Профіль у Firestore (`users/{uid}`) і хмарне сховище фото (лаб. №6).
  final UserRepository? _users;
  final StorageRepository? _storage;
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
      await _users?.saveProfile(
        uid: _user!.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email,
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

  /// FR-06. Готова аватарка за посиланням; [url] == null — видалити фото.
  Future<String?> updatePhoto(String? url) => _changePhoto(
        () async => url,
        source: url == null ? 'removed' : 'preset',
      );

  /// FR-06. Фото з пристрою: файл завантажується в Supabase Storage, а
  /// посилання зберігається у Firebase Auth і в документі `users/{uid}`.
  Future<String?> uploadPhoto(PickedImage image) => _changePhoto(
        () async {
          final storage = _storage;
          if (storage == null) throw const StorageException('Сховище недоступне');
          return storage.uploadImage(image, folder: 'avatars/${_user!.uid}');
        },
        source: 'upload',
      );

  Future<String?> _changePhoto(
    Future<String?> Function() resolveUrl, {
    required String source,
  }) async {
    if (_isUpdatingPhoto) return null;
    _isUpdatingPhoto = true;
    notifyListeners();
    final oldUrl = photoUrl;
    try {
      final url = await resolveUrl();
      await _repository.updatePhotoUrl(url);
      await _users?.saveProfile(
        uid: _user!.uid,
        photoUrl: url,
        clearPhoto: url == null,
      );
      // Попередній файл із нашого сховища більше не потрібен.
      if (oldUrl != null && oldUrl != url) {
        await _storage?.deleteByUrl(oldUrl);
      }
      AnalyticsService.logAvatarChanged(source: source);
      return null;
    } on StorageException catch (e) {
      return e.message;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Не вдалося оновити фото';
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
