import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/repositories/event_repository.dart';
import '../data/repositories/firestore_event_repository.dart';
import '../data/repositories/storage_repository.dart';
import '../data/services/preferences_service.dart';
import 'auth_model.dart';
import 'events_model.dart';
import 'tasks_model.dart';

/// Провайдери, що існують лише поки користувач увійшов: репозиторій
/// заходів, стан заходів (EventsModel) і стан завдань (TasksModel).
/// Після виходу віджет зникає з дерева, і Provider автоматично
/// викликає dispose() у моделей.
class SessionScope extends StatelessWidget {
  final Widget child;

  const SessionScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthModel>();
    final user = auth.user!;
    final name = _displayName(user);

    return MultiProvider(
      providers: [
        // Лаб. №6: дані з Cloud Firestore замість тестових даних.
        Provider<EventRepository>(
          create: (_) => FirestoreEventRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) => EventsModel(
            repository: context.read<EventRepository>(),
            preferences: context.read<PreferencesService>(),
            storage: context.read<StorageRepository>(),
            currentUserId: user.uid,
            currentUserName: name,
            // Ім'я читається щоразу заново (див. EventsModel).
            resolveUserName: () => _displayName(auth.user ?? user),
            currentUserEmail: user.email ?? '',
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => TasksModel(
            repository: context.read<EventRepository>(),
            preferences: context.read<PreferencesService>(),
            currentUserId: user.uid,
          )..load(),
        ),
      ],
      child: child,
    );
  }

  static String _displayName(User user) {
    final name = (user.displayName ?? '').trim();
    return name.isEmpty ? (user.email ?? 'Волонтер') : name;
  }
}
