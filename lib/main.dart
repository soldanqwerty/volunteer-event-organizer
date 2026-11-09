import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/preferences_service.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'state/auth_model.dart';
import 'state/profile_model.dart';
import 'state/session_scope.dart';

Future<void> main() async {
  // Sentry замість Firebase Crashlytics, який не підтримує Web.
  // SentryFlutter.init автоматично налаштовує FlutterError.onError
  // та PlatformDispatcher.instance.onError.
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://ecf310400cc630d7421674c73766f288@o4512324963729408.ingest.de.sentry.io/4512324978999376';
      options.environment = 'development';
      // Не збирати персональні дані (IP, email) у звітах.
      options.sendDefaultPii = false;
    },
    // Ініціалізація Flutter і Firebase виконується в тій самій зоні,
    // що й runApp, тому Sentry перехоплює також помилки під час старту.
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(
        // Глобальні залежності та стан, що живуть увесь час роботи
        // застосунку: репозиторій автентифікації, сховище налаштувань,
        // стан входу та профілю.
        MultiProvider(
          providers: [
            Provider(create: (_) => AuthRepository()),
            Provider(create: (_) => PreferencesService()),
            ChangeNotifierProvider(
              create: (context) => AuthModel(context.read<AuthRepository>()),
            ),
            ChangeNotifierProvider(
              create: (context) =>
                  ProfileModel(context.read<AuthRepository>()),
            ),
          ],
          child: const VolunteerHubApp(),
        ),
      );
    },
  );
}

class VolunteerHubApp extends StatelessWidget {
  const VolunteerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // select: перебудова лише тоді, коли змінюється uid (вхід/вихід),
    // а не при кожній зміні профілю.
    final uid = context.select<AuthModel, String?>((m) => m.user?.uid);

    final app = MaterialApp(
      title: 'VolunteerHub',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );

    if (uid == null) return app;

    // Стан заходів і завдань існує лише під час сеансу користувача.
    // SessionScope розміщено НАД MaterialApp, щоб моделі були доступні
    // і на екранах, відкритих через Navigator.push, і в діалогах.
    // Ключ uid гарантує, що після входу іншого користувача стан
    // створюється заново.
    return SessionScope(key: ValueKey(uid), child: app);
  }
}
