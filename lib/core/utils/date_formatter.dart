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

  /// «Вівторок, 27 жовтня».
  static String weekdayDayMonth(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday, ${date.day} $month';
  }
}
