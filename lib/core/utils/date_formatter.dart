/// Форматування дат українською без додаткових залежностей.
class DateFormatter {
  DateFormatter._();

  static const List<String> _weekdays = [
    'Понеділок',
    'Вівторок',
    'Середа',
    'Четвер',
    "П'ятниця",
    'Субота',
    'Неділя',
  ];

  /// Назви місяців у родовому відмінку: «27 жовтня».
  static const List<String> _months = [
    'січня',
    'лютого',
    'березня',
    'квітня',
    'травня',
    'червня',
    'липня',
    'серпня',
    'вересня',
    'жовтня',
    'листопада',
    'грудня',
  ];

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// «Вівторок, 27 жовтня».
  static String weekdayDayMonth(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday, ${date.day} $month';
  }

  /// «27 жовтня».
  static String dayMonth(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  /// «09:30».
  static String time(DateTime date) =>
      '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

  /// «27 жовтня, 09:30».
  static String dayMonthTime(DateTime date) =>
      '${dayMonth(date)}, ${time(date)}';

  /// «10:00–13:00».
  static String timeRange(DateTime start, DateTime end) =>
      '${time(start)}–${time(end)}';

  /// «24 травня, 10:00–13:00».
  static String dayMonthTimeRange(DateTime start, DateTime end) =>
      '${dayMonth(start)}, ${timeRange(start, end)}';

  /// «Сьогодні, 18:00», «Завтра, 12:00» або «27 жовтня».
  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = day.difference(today).inDays;

    if (difference == 0) return 'Сьогодні, ${time(date)}';
    if (difference == 1) return 'Завтра, ${time(date)}';
    if (difference == -1) return 'Вчора, ${time(date)}';
    return dayMonth(date);
  }
}
