import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/repositories/event_repository.dart';
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
    final user = context.read<AuthModel>().user!;
    final name = (user.displayName ?? '').trim().isEmpty
        ? (user.email ?? 'Волонтер')
        : user.displayName!.trim();

    return MultiProvider(
      providers: [
        Provider<EventRepository>(
          create: (_) => InMemoryEventRepository(
            currentUserId: user.uid,
            currentUserName: name,
            currentUserEmail: user.email ?? '',
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => EventsModel(
            repository: context.read<EventRepository>(),
            preferences: context.read<PreferencesService>(),
            currentUserId: user.uid,
            currentUserName: name,
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
}
