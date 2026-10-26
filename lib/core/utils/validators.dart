/// Набір перевикористовуваних валідаторів для полів форм.
/// Кожен метод повертає null, якщо значення коректне, або текст помилки.
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const int minPasswordLength = 8;

  /// Обов'язкове поле з власним повідомленням, наприклад «Введіть ім'я».
  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Ім'я або прізвище: обов'язкове, щонайменше 2 символи.
  static String? name(String? value, {required String emptyMessage}) {
    final requiredError = required(value, emptyMessage);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) return 'Щонайменше 2 символи';
    return null;
  }

  /// Email: обов'язковий і в правильному форматі.
  static String? email(String? value) {
    final requiredError = required(value, 'Введіть email');
    if (requiredError != null) return requiredError;
    if (!_emailRegExp.hasMatch(value!.trim())) {
      return 'Некоректний формат email';
    }
    return null;
  }

  /// Новий пароль (реєстрація, зміна пароля): щонайменше 8 символів.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Введіть пароль';
    if (value.length < minPasswordLength) {
      return 'Пароль має містити щонайменше $minPasswordLength символів';
    }
    return null;
  }

  /// Пароль під час входу: лише перевірка, що поле не порожнє.
  /// Правильність пароля перевіряє Firebase, а не форма.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Введіть пароль';
    return null;
  }

  /// Підтвердження пароля: має збігатися з основним паролем.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Підтвердіть пароль';
    if (value != original) return 'Паролі не збігаються';
    return null;
  }

  /// Посилання на зображення: обов'язково HTTPS.
  static String? httpsUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Вставте посилання на зображення';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Посилання має починатися з https://';
    }
    return null;
  }
}
