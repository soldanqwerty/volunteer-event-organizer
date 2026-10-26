import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Кореневий віджет: показує вхід або головний екран залежно від стану
/// автентифікації. Завдяки цьому сеанс відновлюється після оновлення сторінки.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthRepository().authStateChanges(),
      builder: (context, snapshot) {
        // Firebase ще перевіряє збережений сеанс.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
