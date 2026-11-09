import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/task_list_tile.dart';
import '../../data/models/event_task.dart';
import '../../state/events_model.dart';
import '../../state/tasks_model.dart';
import '../events/event_details_screen.dart';

/// Екран «Мої завдання» (макет S-15): завдання, призначені поточному
/// користувачу, з фільтром за статусом, сортуванням і швидкою зміною
/// статусу (FR-16).
class MyTasksScreen extends StatelessWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksModel = context.watch<TasksModel>();
    final eventsModel = context.watch<EventsModel>();
    final tasks = tasksModel.myTasks;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Мої завдання', style: textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Нових: ${tasksModel.countMyTasksWithStatus(TaskStatus.newTask)}'
                    '  •  У роботі: '
                    '${tasksModel.countMyTasksWithStatus(TaskStatus.inProgress)}'
                    '  •  Виконано: '
                    '${tasksModel.countMyTasksWithStatus(TaskStatus.done)}',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Усі'),
                        selected: tasksModel.statusFilter == null,
                        onSelected: (_) => tasksModel.setStatusFilter(null),
                      ),
                      for (final status in TaskStatus.values)
                        ChoiceChip(
                          label: Text(status.label),
                          selected: tasksModel.statusFilter == status,
                          onSelected: (_) =>
                              tasksModel.setStatusFilter(status),
                        ),
                      const SizedBox(width: 16),
                      SegmentedButton<TaskSort>(
                        segments: [
                          for (final sort in TaskSort.values)
                            ButtonSegment(
                              value: sort,
                              label: Text(sort.label),
                            ),
                        ],
                        selected: {tasksModel.sort},
                        onSelectionChanged: (value) =>
                            tasksModel.setSort(value.first),
                      ),
                    ],
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
              child: Center(child: Text('Завдань із таким статусом немає')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              sliver: SliverList.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final event = eventsModel.eventById(task.eventId);
                  return TaskListTile(
                    task: task,
                    subtitle: event?.title,
                    onStatusChanged: (status) =>
                        tasksModel.changeStatus(task, status),
                    onTap: event == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailsScreen(eventId: event.id),
                              ),
                            ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
