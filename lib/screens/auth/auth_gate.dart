import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_model.dart';
import '../shell/app_shell.dart';
import 'login_screen.dart';

/// Кореневий екран: показує вхід або основну оболонку залежно від
/// стану [AuthModel]. Сеанс відновлюється після оновлення сторінки,
/// бо Firebase Auth зберігає його сам.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthModel, AuthStatus>((m) => m.status);

    switch (status) {
      case AuthStatus.unknown:
        // Firebase ще перевіряє збережений сеанс.
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const AppShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
