/// Налаштування Supabase Storage (лаб. №6, завдання 8).
///
/// URL проєкту та anon (publishable) ключ є публічними: вони потрапляють
/// у код вебзастосунку, а доступ обмежують політики bucket у Supabase.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = 'https://cewewiyndntwphcmiexh.supabase.co';
  static const anonKey = 'sb_publishable_vvLGkYESOaq9tWNOeqTRJA_i-rXS-mT';

  /// Публічний bucket для обкладинок заходів і фото профілю.
  static const bucket = 'images';
}
