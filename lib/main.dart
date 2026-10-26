import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';

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
      runApp(const VolunteerHubApp());
    },
  );
}

class VolunteerHubApp extends StatelessWidget {
  const VolunteerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolunteerHub',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
