import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/task_list_tile.dart';
import '../../core/widgets/user_avatar.dart';
import '../../state/events_model.dart';
import '../../state/profile_model.dart';
import '../../state/tasks_model.dart';
import '../events/event_details_screen.dart';
import '../events/event_form_dialog.dart';

/// Головний екран (макет S-04, вимога FR-07): вітання, найближчі
/// заходи та активні завдання користувача.
///
/// Бічна панель тепер належить AppShell, тому тут лише вміст сторінки.
/// Дані беруться з ProfileModel, EventsModel і TasksModel.
class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenTasks;

  const HomeScreen({
    super.key,
    required this.onOpenEvents,
    required this.onOpenTasks,
  });

  void _openEvent(BuildContext context, String eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: eventId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final profile = context.watch<ProfileModel>();
    final events = context.watch<EventsModel>();
    final tasks = context.watch<TasksModel>();

    final upcoming = events.upcomingEvents();
    final activeTasks = tasks.myActiveTasks.take(5).toList();
    final firstName =
        profile.firstName.isEmpty ? 'волонтере' : profile.firstName;

    return SingleChildScrollView(
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
                    Text('Головна', style: textTheme.headlineSmall),
                    Text(
                      DateFormatter.weekdayDayMonth(DateTime.now()),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              UserAvatar(
                photoUrl: profile.photoUrl,
                initials: UserAvatar.initialsFrom(profile.displayName),
                radius: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName.isEmpty
                        ? 'Без імені'
                        : profile.displayName,
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    profile.email,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'ДОБРИЙ ДЕНЬ',
            style: textTheme.labelSmall?.copyWith(
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
                      'Вітаємо, $firstName',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сьогодні чудовий день, щоб допомогти іншим',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showEventFormDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Створити захід'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: onOpenEvents,
                icon: const Text('Усі заходи'),
                label: const Icon(Icons.arrow_forward, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SectionHeader(
            title: 'Найближчі заходи',
            trailing: 'Показано ${upcoming.length}',
          ),
          const SizedBox(height: 12),
          if (events.isLoading)
            const _Loading(height: 270)
          else if (upcoming.isEmpty)
            const Text('Найближчих заходів немає')
          else
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final event = upcoming[index];
                  return EventCard(
                    event: event,
                    footnote: '${events.confirmedCount(event.id)}/'
                        '${event.participantLimit} учасників',
                    onTap: () => _openEvent(context, event.id),
                  );
                },
              ),
            ),
          const SizedBox(height: 32),
          _SectionHeader(
            title: 'Мої завдання',
            trailing: 'Активних: ${tasks.myActiveTasks.length}',
            onMore: onOpenTasks,
          ),
          const SizedBox(height: 12),
          if (tasks.isLoading)
            const _Loading(height: 120)
          else if (activeTasks.isEmpty)
            const Text('Активних завдань немає 🎉')
          else
            for (final task in activeTasks)
              TaskListTile(
                task: task,
                subtitle: events.eventById(task.eventId)?.title,
                onStatusChanged: (status) => tasks.changeStatus(task, status),
                onTap: () => _openEvent(context, task.eventId),
              ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback? onMore;

  const _SectionHeader({
    required this.title,
    required this.trailing,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(title, style: textTheme.titleMedium),
        const Spacer(),
        Text(trailing, style: textTheme.bodySmall),
        if (onMore != null) ...[
          const SizedBox(width: 8),
          TextButton(onPressed: onMore, child: const Text('Усі')),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  final double height;

  const _Loading({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
