import 'package:firebase_analytics/firebase_analytics.dart';

/// Реєстрація подій Firebase Analytics.
/// Помилки аналітики ігноруються: вони не повинні впливати на роботу
/// застосунку.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Рекомендована подія: успішна реєстрація.
  static Future<void> logSignUp() =>
      _safe(() => _analytics.logSignUp(signUpMethod: 'email'));

  /// Рекомендована подія: успішний вхід.
  static Future<void> logLogin() =>
      _safe(() => _analytics.logLogin(loginMethod: 'email'));

  /// Власна подія: запит листа для відновлення пароля.
  static Future<void> logPasswordResetRequested() =>
      _safe(() => _analytics.logEvent(name: 'password_reset_requested'));

  /// Власна подія: оновлення імені в профілі.
  static Future<void> logProfileUpdated() =>
      _safe(() => _analytics.logEvent(name: 'profile_updated'));

  /// Власна подія: успішна зміна пароля.
  static Future<void> logPasswordChanged() =>
      _safe(() => _analytics.logEvent(name: 'password_changed'));

  /// Власна подія з параметром: зміна фото профілю.
  /// [source]: 'preset' — готове зображення, 'custom' — власне посилання,
  /// 'removed' — фото видалено.
  static Future<void> logAvatarChanged({required String source}) => _safe(
    () => _analytics.logEvent(
      name: 'avatar_changed',
      parameters: {'source': source},
    ),
  );

  static Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Аналітика необов'язкова — ігноруємо помилки.
    }
  }
}
