import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/widgets/confirm_delete_dialog.dart';
import '../../core/widgets/task_list_tile.dart';
import '../../data/models/event_task.dart';
import '../../data/models/participant.dart';
import '../../data/models/volunteer_event.dart';
import '../../state/events_model.dart';
import '../../state/tasks_model.dart';
import 'event_form_dialog.dart';
import 'task_form_dialog.dart';

/// Екран деталей заходу (макет S-06) з вкладками «Опис», «Учасники»
/// та «Завдання». Набір дій залежить від ролі: організатор редагує й
/// видаляє захід, керує заявками та завданнями; волонтер записується
/// на захід або скасовує участь.
class EventDetailsScreen extends StatelessWidget {
  /// Передаємо id, а не об'єкт: після редагування екран бере
  /// актуальну версію заходу з EventsModel.
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  Future<void> _deleteEvent(BuildContext context, VolunteerEvent event) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Видалити захід?',
      message: 'Захід «${event.title}», його учасників і завдання буде '
          'видалено. Цю дію неможливо скасувати.',
    );
    if (!confirmed || !context.mounted) return;

    final events = context.read<EventsModel>();
    final tasks = context.read<TasksModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (await events.deleteEvent(event.id)) {
      tasks.removeTasksOfEvent(event.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Захід видалено')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(events.errorMessage ?? 'Сталася помилка')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // select: екран перебудовується лише тоді, коли змінився сам захід.
    final event = context.select<EventsModel, VolunteerEvent?>(
      (m) => m.eventById(eventId),
    );

    // Захід видалено — показуємо порожній екран, поки виконується pop.
    if (event == null) return const Scaffold();

    final isOrganizer = context.read<EventsModel>().isOrganizer(event);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.title),
          actions: [
            if (isOrganizer) ...[
              IconButton(
                tooltip: 'Редагувати',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showEventFormDialog(context, event: event),
              ),
              IconButton(
                tooltip: 'Видалити',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteEvent(context, event),
              ),
              const SizedBox(width: 8),
            ],
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Опис'),
              Tab(text: 'Учасники'),
              Tab(text: 'Завдання'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DescriptionTab(event: event),
            _ParticipantsTab(event: event, isOrganizer: isOrganizer),
            _TasksTab(event: event, isOrganizer: isOrganizer),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ «Опис»

class _DescriptionTab extends StatelessWidget {
  final VolunteerEvent event;

  const _DescriptionTab({required this.event});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            avatar: CircleAvatar(
              radius: 5,
              backgroundColor: event.category.color,
            ),
            label: Text(event.category.label),
            side: BorderSide.none,
            backgroundColor: event.category.color.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.calendar_today,
          text: DateFormatter.weekdayDayMonth(event.dateTime),
        ),
        _InfoRow(
          icon: Icons.access_time,
          text: DateFormatter.time(event.dateTime),
        ),
        _InfoRow(icon: Icons.location_on_outlined, text: event.location),
        _InfoRow(
          icon: Icons.person_outline,
          text: 'Організатор: ${event.organizerName}',
        ),
        const SizedBox(height: 24),
        Text('Опис', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(event.description, style: textTheme.bodyLarge),
        const SizedBox(height: 32),
        _ParticipationPanel(event: event),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Блок запису на захід (FR-12). Consumer перебудовує лише цю частину
/// екрана, коли змінюється список учасників.
class _ParticipationPanel extends StatelessWidget {
  final VolunteerEvent event;

  const _ParticipationPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsModel>(
      builder: (context, model, _) {
        final confirmed = model.confirmedCount(event.id);
        final progress = (confirmed / event.participantLimit).clamp(0.0, 1.0);
        final participation = model.myParticipation(event.id);

        Widget action;
        if (model.isOrganizer(event)) {
          action = const Text('Ви організатор цього заходу');
        } else if (event.isPast) {
          action = const Text('Захід уже завершився');
        } else if (participation != null) {
          action = Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(participation.status.label),
                side: BorderSide.none,
                labelStyle: TextStyle(color: participation.status.color),
                backgroundColor:
                    participation.status.color.withValues(alpha: 0.12),
              ),
              OutlinedButton(
                onPressed: model.isSaving
                    ? null
                    : () => model.leaveEvent(event),
                child: const Text('Скасувати участь'),
              ),
            ],
          );
        } else if (model.isFull(event)) {
          action = const Text('Усі місця зайняті');
        } else {
          action = FilledButton.icon(
            onPressed: model.isSaving ? null : () => model.joinEvent(event),
            icon: const Icon(Icons.how_to_reg),
            label: const Text('Записатися'),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Учасники: $confirmed з ${event.participantLimit}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 16),
                action,
              ],
            ),
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------- «Учасники»

class _ParticipantsTab extends StatelessWidget {
  final VolunteerEvent event;
  final bool isOrganizer;

  const _ParticipantsTab({required this.event, required this.isOrganizer});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<EventsModel>();
    final participants = model.participantsOf(event.id);

    if (participants.isEmpty) {
      return const Center(child: Text('Поки що ніхто не записався'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: participants.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final participant = participants[index];
        return ListTile(
          leading: CircleAvatar(child: Text(participant.name[0])),
          title: Text(participant.name),
          subtitle: Text(participant.email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                participant.status.label,
                style: TextStyle(color: participant.status.color),
              ),
              if (isOrganizer)
                _ParticipantMenu(participant: participant, model: model),
            ],
          ),
        );
      },
    );
  }
}

/// Меню організатора: підтвердити, відхилити або видалити учасника
/// (FR-13).
class _ParticipantMenu extends StatelessWidget {
  final Participant participant;
  final EventsModel model;

  const _ParticipantMenu({required this.participant, required this.model});

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Видалити учасника?',
      message: '${participant.name} буде видалено зі списку учасників.',
    );
    if (confirmed) await model.removeParticipant(participant);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Дії',
      enabled: !model.isSaving,
      onSelected: (action) {
        switch (action) {
          case 'confirm':
            model.setParticipantStatus(
              participant,
              ParticipantStatus.confirmed,
            );
          case 'reject':
            model.setParticipantStatus(
              participant,
              ParticipantStatus.rejected,
            );
          case 'remove':
            _remove(context);
        }
      },
      itemBuilder: (_) => [
        if (participant.status != ParticipantStatus.confirmed)
          const PopupMenuItem(value: 'confirm', child: Text('Підтвердити')),
        if (participant.status != ParticipantStatus.rejected)
          const PopupMenuItem(value: 'reject', child: Text('Відхилити')),
        const PopupMenuItem(value: 'remove', child: Text('Видалити')),
      ],
    );
  }
}

// --------------------------------------------------------- «Завдання»

class _TasksTab extends StatelessWidget {
  final VolunteerEvent event;
  final bool isOrganizer;

  const _TasksTab({required this.event, required this.isOrganizer});

  Future<void> _delete(BuildContext context, EventTask task) async {
    final tasks = context.read<TasksModel>();
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Видалити завдання?',
      message: 'Завдання «${task.title}» буде видалено.',
    );
    if (confirmed) await tasks.deleteTask(task.id);
  }

  @override
  Widget build(BuildContext context) {
    final tasksModel = context.watch<TasksModel>();
    final tasks = tasksModel.tasksOf(event.id);
    final currentUserId = tasksModel.currentUserId;

    return Scaffold(
      floatingActionButton: isOrganizer
          ? FloatingActionButton.extended(
              onPressed: () => showTaskFormDialog(context, event: event),
              icon: const Icon(Icons.add_task),
              label: const Text('Додати завдання'),
            )
          : null,
      body: tasks.isEmpty
          ? const Center(child: Text('Завдань ще немає'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                // Статус змінює організатор або виконавець (FR-16).
                final canChangeStatus =
                    isOrganizer || task.assigneeId == currentUserId;

                return TaskListTile(
                  task: task,
                  showAssignee: true,
                  onTap: isOrganizer
                      ? () => showTaskFormDialog(
                            context,
                            event: event,
                            task: task,
                          )
                      : null,
                  onStatusChanged: canChangeStatus
                      ? (status) => tasksModel.changeStatus(task, status)
                      : null,
                  trailingAction: isOrganizer
                      ? IconButton(
                          tooltip: 'Видалити завдання',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(context, task),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
