import 'package:shared_preferences/shared_preferences.dart';

/// Збереження налаштувань користувача на пристрої (SharedPreferences).
///
/// Що зберігається і навіщо:
/// - фільтр дати, категорія та сортування на екрані «Заходи»;
/// - фільтр статусу на екрані «Мої завдання».
/// Після перезапуску застосунку користувач бачить ті самі фільтри.
///
/// Токен сеансу тут НЕ зберігається: Firebase Auth зберігає його сам.
class PreferencesService {
  static const _eventsDateFilterKey = 'events_date_filter';
  static const _eventsCategoryKey = 'events_category';
  static const _eventsSortKey = 'events_sort';
  static const _tasksStatusFilterKey = 'tasks_status_filter';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---------------------------------------------------------------- Заходи

  Future<String?> loadEventsDateFilter() async =>
      (await _prefs).getString(_eventsDateFilterKey);

  Future<void> saveEventsDateFilter(String value) async {
    await (await _prefs).setString(_eventsDateFilterKey, value);
  }

  /// null — «Усі категорії».
  Future<String?> loadEventsCategory() async =>
      (await _prefs).getString(_eventsCategoryKey);

  Future<void> saveEventsCategory(String? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_eventsCategoryKey);
    } else {
      await prefs.setString(_eventsCategoryKey, value);
    }
  }

  Future<String?> loadEventsSort() async =>
      (await _prefs).getString(_eventsSortKey);

  Future<void> saveEventsSort(String value) async {
    await (await _prefs).setString(_eventsSortKey, value);
  }

  // ------------------------------------------------------------- Завдання

  /// null — «Усі статуси».
  Future<String?> loadTasksStatusFilter() async =>
      (await _prefs).getString(_tasksStatusFilterKey);

  Future<void> saveTasksStatusFilter(String? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_tasksStatusFilterKey);
    } else {
      await prefs.setString(_tasksStatusFilterKey, value);
    }
  }
}
