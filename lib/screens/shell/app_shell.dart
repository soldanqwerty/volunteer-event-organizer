import 'package:flutter/material.dart';

import '../../core/widgets/app_sidebar.dart';
import '../events/events_list_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/my_tasks_screen.dart';

/// Основна оболонка після входу: бічна панель і чотири розділи.
///
/// Номер вибраного розділу — ефемерний стан (потрібен лише цьому
/// віджету), тому він зберігається через setState, а не в Provider.
/// IndexedStack зберігає стан кожного розділу (прокрутку, введений
/// пошук) під час перемикання.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
          ),
          const VerticalDivider(width: 1),
          Expanded(
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
        ],
      ),
    );
  }
}
