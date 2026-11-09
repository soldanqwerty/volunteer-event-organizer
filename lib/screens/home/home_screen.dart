import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/task_status_pill.dart';
import '../../data/models/event_task.dart';
import '../../state/events_model.dart';
import '../../state/profile_model.dart';
import '../../state/tasks_model.dart';
import '../events/event_form_dialog.dart';
import '../shell/app_shell.dart';

/// Головний екран (макет S-04, вимога FR-07): вітання, найближчі
/// заходи та активні завдання користувача.
///
/// Бічна панель належить AppShell, тому тут лише вміст сторінки.
/// Дані беруться з ProfileModel, EventsModel і TasksModel.
class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenTasks;

  const HomeScreen({
    super.key,
    required this.onOpenEvents,
    required this.onOpenTasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final firstName = context.select<ProfileModel, String>((m) => m.firstName);
    final events = context.watch<EventsModel>();
    final tasks = context.watch<TasksModel>();

    final upcoming = events.upcomingEvents();
    final weekLater = DateTime.now().add(const Duration(days: 7));
    final thisWeek =
        upcoming.where((e) => e.dateTime.isBefore(weekLater)).length;
    final activeTasks = tasks.myActiveTasks;

    return Column(
      children: [
        AppTopBar(
          title: 'Головна',
          subtitle: DateFormatter.weekdayDayMonth(DateTime.now()),
          showUserName: true,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ДОБРИЙ ДЕНЬ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Вітаємо, ${firstName.isEmpty ? 'волонтере' : firstName}',
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Сьогодні чудовий день, щоб допомогти іншим.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () => showEventFormDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Створити захід'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        iconAlignment: IconAlignment.end,
                      ),
                      onPressed: onOpenEvents,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Усі заходи'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Найближчі заходи',
                  trailing: 'Цього тижня: $thisWeek',
                  highlight: true,
                ),
                const SizedBox(height: 12),
                if (events.isLoading)
                  const _Loading(height: 140)
                else if (upcoming.isEmpty)
                  const Text('Найближчих заходів немає')
                else
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          Expanded(
                            child: i < upcoming.length
                                ? EventCompactCard(
                                    event: upcoming[i],
                                    onTap: () => AppShell.openEvent(
                                      context,
                                      upcoming[i].id,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Мої завдання',
                  trailing: 'Активних: ${activeTasks.length}',
                  onMore: onOpenTasks,
                ),
                const SizedBox(height: 12),
                if (tasks.isLoading)
                  const _Loading(height: 120)
                else if (activeTasks.isEmpty)
                  const Text('Активних завдань немає')
                else
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < activeTasks.length && i < 5;
                            i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _TaskRow(
                            task: activeTasks[i],
                            onStatusChanged: (status) =>
                                tasks.changeStatus(activeTasks[i], status),
                            onTap: () => AppShell.openEvent(
                              context,
                              activeTasks[i].eventId,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final EventTask task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onTap;

  const _TaskRow({
    required this.task,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: task.priority.color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                task.title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 14, color: muted),
            const SizedBox(width: 6),
            SizedBox(
              width: 120,
              child: Text(
                DateFormatter.relativeDay(task.dueDate),
                style: theme.textTheme.bodySmall,
              ),
            ),
            SizedBox(
              width: 110,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TaskStatusPill(task: task, onChanged: onStatusChanged),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;
  final bool highlight;
  final VoidCallback? onMore;

  const _SectionHeader({
    required this.title,
    required this.trailing,
    this.highlight = false,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          trailing,
          style: theme.textTheme.bodySmall?.copyWith(
            color: highlight ? theme.colorScheme.primary : null,
            fontWeight: highlight ? FontWeight.w600 : null,
          ),
        ),
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
