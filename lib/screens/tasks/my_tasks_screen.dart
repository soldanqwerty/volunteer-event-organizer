import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/simple_table.dart';
import '../../core/widgets/task_status_pill.dart';
import '../../data/models/event_task.dart';
import '../../state/events_model.dart';
import '../../state/tasks_model.dart';
import '../shell/app_shell.dart';

/// Екран «Мої завдання» (макет S-15, FR-16): завдання, призначені
/// поточному користувачу, з фільтром за статусом, сортуванням і
/// швидкою зміною статусу.
class MyTasksScreen extends StatelessWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksModel = context.watch<TasksModel>();
    final eventsModel = context.watch<EventsModel>();
    final tasks = tasksModel.myTasks;
    final activeCount = tasksModel.myActiveTasks.length;

    return Column(
      children: [
        AppTopBar(
          title: 'Мої завдання',
          subtitle: 'Активних: $activeCount',
          showUserName: true,
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              label: 'Усі',
                              selected: tasksModel.statusFilter == null,
                              onTap: () => tasksModel.setStatusFilter(null),
                            ),
                            for (final status in TaskStatus.values)
                              _StatusChip(
                                label: status.label,
                                selected: tasksModel.statusFilter == status,
                                onTap: () =>
                                    tasksModel.setStatusFilter(status),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<TaskSort>(
                        tooltip: '',
                        position: PopupMenuPosition.under,
                        onSelected: tasksModel.setSort,
                        itemBuilder: (_) => [
                          for (final sort in TaskSort.values)
                            CheckedPopupMenuItem(
                              value: sort,
                              checked: sort == tasksModel.sort,
                              child: Text(sort.label),
                            ),
                        ],
                        child: IgnorePointer(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.sort, size: 18),
                            label: Text('Сортування: ${tasksModel.sort.label}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tasksModel.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (tasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Завдань із таким статусом немає'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SimpleTable(
                          columns: const [
                            ('ЗАВДАННЯ', 5),
                            ('ЗАХІД', 4),
                            ('ТЕРМІН', 3),
                            ('СТАТУС', 2),
                          ],
                          onRowTap: (i) =>
                              AppShell.openEvent(context, tasks[i].eventId),
                          rows: [
                            for (final task in tasks)
                              _row(context, task, eventsModel, tasksModel),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _row(
    BuildContext context,
    EventTask task,
    EventsModel events,
    TasksModel tasks,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isOverdue =
        task.status != TaskStatus.done && task.dueDate.isBefore(DateTime.now());

    return [
      Row(
        children: [
          Tooltip(
            message: 'Пріоритет: ${task.priority.label}',
            child: CircleAvatar(radius: 4, backgroundColor: task.priority.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: task.status == TaskStatus.done
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Icon(Icons.event_note_outlined, size: 14, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              events.eventById(task.eventId)?.title ?? '—',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: isOverdue ? Colors.red : muted,
          ),
          const SizedBox(width: 6),
          Text(
            DateFormatter.relativeDay(task.dueDate),
            style: isOverdue ? const TextStyle(color: Colors.red) : null,
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TaskStatusPill(
          task: task,
          onChanged: (status) => tasks.changeStatus(task, status),
        ),
      ),
    ];
  }
}

/// Чип фільтра статусу з галочкою, як на макеті.
class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      shape: const StadiumBorder(),
      showCheckmark: true,
      checkmarkColor: colorScheme.onPrimary,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
