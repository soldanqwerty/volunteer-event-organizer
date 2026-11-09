import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/confirm_delete_dialog.dart';
import '../../core/widgets/event_cover.dart';
import '../../core/widgets/simple_table.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/task_status_pill.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/event_task.dart';
import '../../data/models/participant.dart';
import '../../data/models/volunteer_event.dart';
import '../../state/events_model.dart';
import '../../state/tasks_model.dart';
import 'event_form_dialog.dart';
import 'task_form_dialog.dart';

/// Екран деталей заходу (макет S-06, FR-09 – FR-17).
///
/// Ліворуч — картка заходу з діями, праворуч — вкладки «Опис»,
/// «Учасники» та «Завдання». Набір дій залежить від ролі: організатор
/// редагує й видаляє захід, керує заявками та завданнями; волонтер
/// долучається до заходу або скасовує участь.
class EventDetailsScreen extends StatelessWidget {
  /// Передаємо id, а не об'єкт: після редагування екран бере
  /// актуальну версію заходу з EventsModel.
  final String eventId;
  final VoidCallback onBack;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // select: екран перебудовується лише тоді, коли змінився сам захід.
    final event = context.select<EventsModel, VolunteerEvent?>(
      (m) => m.eventById(eventId),
    );

    // Захід видалено — нічого не показуємо, onBack уже викликано.
    if (event == null) return const SizedBox.shrink();

    final isOrganizer = context.read<EventsModel>().isOrganizer(event);

    return Column(
      children: [
        AppTopBar(
          title: 'Деталі заходу',
          subtitle: 'Заходи / ${event.title}',
          onBack: onBack,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 340,
                  child: _EventInfoCard(
                    event: event,
                    isOrganizer: isOrganizer,
                    onDeleted: onBack,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TabsCard(event: event, isOrganizer: isOrganizer),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------- Ліва картка заходу

class _EventInfoCard extends StatelessWidget {
  final VolunteerEvent event;
  final bool isOrganizer;
  final VoidCallback onDeleted;

  const _EventInfoCard({
    required this.event,
    required this.isOrganizer,
    required this.onDeleted,
  });

  Future<void> _delete(BuildContext context) async {
    final events = context.read<EventsModel>();
    final tasks = context.read<TasksModel>();
    final participantsCount = events.participantsOf(event.id).length;
    final tasksCount = tasks.tasksOf(event.id).length;

    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Видалити захід?',
      message: 'Цю дію неможливо скасувати. Захід, учасники та завдання '
          'будуть видалені назавжди.',
      details: [
        (
          Icons.calendar_today_outlined,
          '${event.title} — ${DateFormatter.dayMonth(event.dateTime)}',
        ),
        (Icons.group_outlined, 'Зареєстрованих учасників: $participantsCount'),
        (Icons.task_alt, "Пов'язаних завдань: $tasksCount"),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (await events.deleteEvent(event.id)) {
      tasks.removeTasksOfEvent(event.id);
      onDeleted();
      messenger.showSnackBar(const SnackBar(content: Text('Захід видалено')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(events.errorMessage ?? 'Сталася помилка')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Consumer перебудовує лише цю картку, коли змінюються учасники.
    return Consumer<EventsModel>(
      builder: (context, model, _) {
        final confirmed = model.confirmedCount(event.id);
        final badge = RegistrationBadge.of(event, confirmed);
        final participation = model.myParticipation(event.id);

        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 170,
                child: EventCover(
                  category: event.category,
                  iconSize: 64,
                  topLeft: StatusPill(
                    label: event.category.label,
                    color: event.category.color,
                    onImage: true,
                  ),
                  bottomLeft: StatusPill(
                    label: badge == RegistrationBadge.open ||
                            badge == RegistrationBadge.soon
                        ? 'Реєстрація відкрита'
                        : badge.label,
                    color: badge.color,
                    onImage: true,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledInfo(
                        icon: Icons.schedule,
                        label: 'ДАТА Й ЧАС',
                        value: DateFormatter.dayMonthTimeRange(
                          event.dateTime,
                          event.endDateTime,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LabeledInfo(
                        icon: Icons.location_on_outlined,
                        label: 'АДРЕСА',
                        value: event.location,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            UserAvatar(
                              photoUrl: null,
                              initials:
                                  UserAvatar.initialsFrom(event.organizerName),
                              radius: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Організатор',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  Text(
                                    event.organizerName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.group_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text('$confirmed/${event.participantLimit}'),
                          ],
                        ),
                      ),
                      if (participation != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Ваша заявка: '),
                            StatusPill(
                              label: participation.status.label,
                              color: participation.status.color,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _MainAction(
                        event: event,
                        model: model,
                        isOrganizer: isOrganizer,
                        participation: participation,
                      ),
                    ),
                    if (isOrganizer) ...[
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Редагувати',
                        onPressed: () =>
                            showEventFormDialog(context, event: event),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Видалити',
                        color: colorScheme.error,
                        onPressed: () => _delete(context),
                        icon: const Icon(Icons.delete_outline, size: 20),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Головна кнопка картки: «Долучитися» / «Скасувати участь» (FR-12).
class _MainAction extends StatelessWidget {
  final VolunteerEvent event;
  final EventsModel model;
  final bool isOrganizer;
  final Participant? participation;

  const _MainAction({
    required this.event,
    required this.model,
    required this.isOrganizer,
    required this.participation,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(minimumSize: const Size(0, 48));

    if (isOrganizer) {
      return FilledButton.tonalIcon(
        style: style,
        onPressed: null,
        icon: const Icon(Icons.star_outline),
        label: const Text('Ви організатор'),
      );
    }
    if (event.isPast) {
      return FilledButton(
        style: style,
        onPressed: null,
        child: const Text('Захід завершився'),
      );
    }
    if (participation != null) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: model.isSaving ? null : () => model.leaveEvent(event),
        icon: const Icon(Icons.logout),
        label: const Text('Скасувати участь'),
      );
    }
    if (model.isFull(event)) {
      return FilledButton(
        style: style,
        onPressed: null,
        child: const Text('Місць немає'),
      );
    }
    return FilledButton.icon(
      style: style,
      onPressed: model.isSaving ? null : () => model.joinEvent(event),
      icon: const Icon(Icons.group_add_outlined),
      label: const Text('Долучитися'),
    );
  }
}

class _LabeledInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LabeledInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------- Права картка з вкладками

class _TabsCard extends StatelessWidget {
  final VolunteerEvent event;
  final bool isOrganizer;

  const _TabsCard({required this.event, required this.isOrganizer});

  @override
  Widget build(BuildContext context) {
    final participantsCount = context.select<EventsModel, int>(
      (m) => m.participantsOf(event.id).length,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: DefaultTabController(
        // Як на макеті, за замовчуванням відкрито «Учасники».
        length: 3,
        initialIndex: 1,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(text: 'Опис'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Учасники'),
                      const SizedBox(width: 6),
                      Badge(
                        label: Text('$participantsCount'),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
                const Tab(text: 'Завдання'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DescriptionTab(event: event),
                  _ParticipantsTab(event: event, isOrganizer: isOrganizer),
                  _TasksTab(event: event, isOrganizer: isOrganizer),
                ],
              ),
            ),
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
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Про захід',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(event.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoTile(label: 'Категорія', value: event.category.label),
            _InfoTile(
              label: 'Дата',
              value: DateFormatter.weekdayDayMonth(event.dateTime),
            ),
            _InfoTile(
              label: 'Час',
              value: DateFormatter.timeRange(
                event.dateTime,
                event.endDateTime,
              ),
            ),
            _InfoTile(
              label: 'Ліміт учасників',
              value: '${event.participantLimit}',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------- «Учасники»

class _ParticipantsTab extends StatelessWidget {
  final VolunteerEvent event;
  final bool isOrganizer;

  const _ParticipantsTab({required this.event, required this.isOrganizer});

  Future<void> _remove(
    BuildContext context,
    EventsModel model,
    Participant participant,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Видалити учасника?',
      message: '${participant.name} буде видалено зі списку учасників.',
    );
    if (confirmed) await model.removeParticipant(participant);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<EventsModel>();
    final participants = model.participantsOf(event.id);
    final free = (event.participantLimit - model.confirmedCount(event.id))
        .clamp(0, event.participantLimit);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Учасники',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isOrganizer
                        ? 'Керуйте заявками учасників цього заходу'
                        : 'Волонтери, які долучилися до заходу',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Вільних місць', style: theme.textTheme.labelSmall),
                  Text(
                    '$free із ${event.participantLimit}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (participants.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Поки що ніхто не долучився')),
          )
        else
          SimpleTable(
            columns: const [('УЧАСНИК', 5), ('СТАТУС', 3), ('ДІЇ', 2)],
            rows: [
              for (final p in participants)
                [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.6),
                        child: Text(
                          UserAvatar.initialsFrom(p.name),
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              p.email,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(
                      label: p.status.label,
                      color: p.status.color,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: !isOrganizer
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SquareAction(
                                icon: Icons.check,
                                color: Colors.green,
                                tooltip: 'Підтвердити',
                                onPressed: model.isSaving ||
                                        p.status == ParticipantStatus.confirmed
                                    ? null
                                    : () => model.setParticipantStatus(
                                          p,
                                          ParticipantStatus.confirmed,
                                        ),
                              ),
                              const SizedBox(width: 6),
                              _SquareAction(
                                icon: Icons.close,
                                color: Colors.red,
                                // Відхилену заявку можна прибрати зі списку.
                                tooltip: p.status == ParticipantStatus.rejected
                                    ? 'Видалити зі списку'
                                    : 'Відхилити',
                                onPressed: model.isSaving
                                    ? null
                                    : p.status == ParticipantStatus.rejected
                                        ? () => _remove(context, model, p)
                                        : () => model.setParticipantStatus(
                                              p,
                                              ParticipantStatus.rejected,
                                            ),
                              ),
                            ],
                          ),
                  ),
                ],
            ],
          ),
        const SizedBox(height: 12),
        Text(
          'Показано ${participants.length} з ${participants.length} учасників',
          style: theme.textTheme.bodySmall,
        ),
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
      message: 'Цю дію неможливо скасувати.',
      details: [
        (Icons.task_alt, task.title),
        (Icons.calendar_today_outlined,
            'Термін: ${DateFormatter.dayMonth(task.dueDate)}'),
      ],
    );
    if (confirmed) await tasks.deleteTask(task.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksModel = context.watch<TasksModel>();
    final tasks = tasksModel.tasksOf(event.id);
    final currentUserId = tasksModel.currentUserId;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Завдань: ${tasks.length}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (isOrganizer)
              FilledButton.icon(
                onPressed: () => showTaskFormDialog(context, event: event),
                icon: const Icon(Icons.add),
                label: const Text('Додати завдання'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Завдань ще немає')),
          )
        else
          SimpleTable(
            columns: [
              ('ЗАВДАННЯ', 5),
              ('ВИКОНАВЕЦЬ', 4),
              ('ТЕРМІН', 3),
              ('СТАТУС', 3),
              if (isOrganizer) ('ДІЇ', 2),
            ],
            rows: [
              for (final task in tasks)
                [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: task.priority.color,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  task.assigneeName == null
                      ? Text(
                          'Не призначено',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        )
                      : Row(
                          children: [
                            UserAvatar(
                              photoUrl: null,
                              initials:
                                  UserAvatar.initialsFrom(task.assigneeName),
                              radius: 12,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.assigneeName!,
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
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(DateFormatter.dayMonth(task.dueDate)),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TaskStatusPill(
                      task: task,
                      // Статус змінює організатор або виконавець (FR-16).
                      onChanged: isOrganizer || task.assigneeId == currentUserId
                          ? (status) => tasksModel.changeStatus(task, status)
                          : null,
                    ),
                  ),
                  if (isOrganizer)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _SquareAction(
                          icon: Icons.edit_outlined,
                          color: theme.colorScheme.onSurface,
                          tooltip: 'Редагувати',
                          onPressed: () => showTaskFormDialog(
                            context,
                            event: event,
                            task: task,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _SquareAction(
                          icon: Icons.delete_outline,
                          color: Colors.red,
                          tooltip: 'Видалити',
                          onPressed: () => _delete(context, task),
                        ),
                      ],
                    ),
                ],
            ],
          ),
      ],
    );
  }
}

// ------------------------------------------------------ Спільні елементи

/// Маленька квадратна кнопка дії (✓, ✕, олівець, кошик) з макета.
class _SquareAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _SquareAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onPressed == null
                ? Colors.transparent
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? color.withValues(alpha: 0.4) : color,
          ),
        ),
      ),
    );
  }
}
