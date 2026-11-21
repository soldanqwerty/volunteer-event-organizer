/// Налаштування Supabase Storage (лаб. №6, завдання 8).
///
/// URL проєкту та anon (publishable) ключ є публічними: вони потрапляють
/// у код вебзастосунку, а доступ обмежують політики bucket у Supabase.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = 'https://YOUR-PROJECT.supabase.co';
  static const anonKey = 'YOUR-ANON-KEY';

  /// Публічний bucket для обкладинок заходів і фото профілю.
  static const bucket = 'images';
}
