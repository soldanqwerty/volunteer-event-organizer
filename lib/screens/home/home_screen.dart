import 'package:flutter/material.dart';

import '../../core/widgets/app_sidebar.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/task_list_tile.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _userName = 'Олено';
  static const String _fullName = 'Олена Коваль';
  static const String _role = 'Координаторка';

  static const _nearbyEvents = [
    EventPreview(
      title: 'Чистий парк разом',
      date: '24 травня',
      time: '10:00',
      location: 'Парк Наталка',
      indicatorColor: Colors.green,
    ),
    EventPreview(
      title: 'Продукти для родин',
      date: '28 травня',
      time: '12:30',
      location: 'Волонтерський центр',
      indicatorColor: Colors.orange,
    ),
    EventPreview(
      title: 'День турботи про тварин',
      date: '2 червня',
      time: '11:00',
      location: 'Притулок "Сіріус"',
      indicatorColor: Colors.purple,
    ),
  ];

  static const _myTasks = [
    TaskPreview(
      title: 'Підтвердити список учасників',
      dueDate: 'Сьогодні, 18:00',
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
    ),
    TaskPreview(
      title: 'Зібрати інвентар для прибирання',
      dueDate: '23 травня',
      priority: TaskPriority.medium,
      status: TaskStatus.newTask,
    ),
    TaskPreview(
      title: 'Зателефонувати координатору притулку',
      dueDate: '30 травня',
      priority: TaskPriority.low,
      status: TaskStatus.newTask,
    ),
  ];

  void _onNavDestinationSelected(int index) {
    switch (index) {
      case 0:
        break;
      case 3:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цей розділ буде додано пізніше')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 0,
            onDestinationSelected: _onNavDestinationSelected,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Головна',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              "П'ятниця, 23 травня",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          'ОК',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _role,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'ДОБРИЙ ДЕНЬ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Вітаємо, $_userName',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Сьогодні чудовий день, щоб допомогти іншим',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Створити захід'),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Text('Усі заходи'),
                        label: const Icon(Icons.arrow_forward, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        'Найближчі заходи',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${_nearbyEvents.length} заходи цього тижня',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nearbyEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) =>
                          EventCard(event: _nearbyEvents[index]),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        'Мої завдання',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${_myTasks.length} активні',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._myTasks.map((task) => TaskListTile(task: task)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
