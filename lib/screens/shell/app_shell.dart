import 'package:flutter/material.dart';

import '../../core/widgets/app_sidebar.dart';
import '../events/event_details_screen.dart';
import '../events/events_list_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/my_tasks_screen.dart';

/// Основна оболонка після входу: бічна панель і вміст розділу.
///
/// Вибраний розділ і відкритий захід — ефемерний стан (потрібен лише
/// цьому віджету), тому він зберігається через setState, а не в Provider.
/// Деталі заходу відкриваються всередині оболонки, щоб бічна панель
/// залишалася видимою, як на макеті S-06.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Відкрити деталі заходу з будь-якого екрана всередині оболонки.
  static void openEvent(BuildContext context, String eventId) {
    context.findAncestorStateOfType<_AppShellState>()?._openEvent(eventId);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  /// id відкритого заходу; null — показується вибраний розділ.
  String? _openedEventId;

  void _select(int index) => setState(() {
        _selectedIndex = index;
        _openedEventId = null;
      });

  void _openEvent(String eventId) => setState(() => _openedEventId = eventId);

  void _closeEvent() => setState(() => _openedEventId = null);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            // Поки відкрито захід, підсвічується розділ «Заходи».
            selectedIndex: _openedEventId != null ? 1 : _selectedIndex,
            onDestinationSelected: _select,
          ),
          VerticalDivider(width: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: ColoredBox(
              color: colorScheme.surfaceContainerLow,
              child: Stack(
                children: [
                  // IndexedStack зберігає стан кожного розділу (прокрутку,
                  // пошук) під час перемикання.
                  Offstage(
                    offstage: _openedEventId != null,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        HomeScreen(
                          onOpenEvents: () => _select(1),
                          onOpenTasks: () => _select(2),
                        ),
                        const EventsListScreen(),
                        const MyTasksScreen(),
                        const ProfileScreen(),
                      ],
                    ),
                  ),
                  if (_openedEventId != null)
                    EventDetailsScreen(
                      key: ValueKey(_openedEventId),
                      eventId: _openedEventId!,
                      onBack: _closeEvent,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
