import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/date_time_field.dart';
import '../../core/widgets/form_dialog_shell.dart';
import '../../data/models/event_task.dart';
import '../../data/models/participant.dart';
import '../../data/models/volunteer_event.dart';
import '../../state/events_model.dart';
import '../../state/tasks_model.dart';

/// Варіант виконавця у випадному списку: організатор або
/// підтверджений учасник заходу.
typedef _Assignee = ({String id, String name});

/// Відкриває форму завдання (макет S-10). [task] == null — створення.
Future<bool> showTaskFormDialog(
  BuildContext context, {
  required VolunteerEvent event,
  EventTask? task,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TaskFormDialog(event: event, task: task),
  );
  return saved ?? false;
}

/// Форма створення, редагування та розподілу завдання
/// (FR-14, FR-15).
class TaskFormDialog extends StatefulWidget {
  final VolunteerEvent event;
  final EventTask? task;

  const TaskFormDialog({super.key, required this.event, this.task});

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _dueDate;
  late TaskPriority _priority;
  String? _assigneeId;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate ??
        widget.event.dateTime.subtract(const Duration(days: 1));
    _priority = task?.priority ?? TaskPriority.medium;
    _assigneeId = task?.assigneeId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Виконавцем може бути організатор або підтверджений учасник.
  List<_Assignee> _assigneeOptions(EventsModel events) {
    return [
      (id: widget.event.organizerId, name: widget.event.organizerName),
      for (final p in events.participantsOf(widget.event.id))
        if (p.status == ParticipantStatus.confirmed &&
            p.userId != widget.event.organizerId)
          (id: p.userId, name: p.name),
    ];
  }

  Future<void> _onSavePressed(List<_Assignee> options) async {
    if (!_formKey.currentState!.validate()) return;

    final model = context.read<TasksModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final assignee =
        options.where((a) => a.id == _assigneeId).firstOrNull;

    final ok = _isEditing
        ? await model.updateTask(
            widget.task!.copyWith(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              dueDate: _dueDate,
              priority: _priority,
              assigneeId: assignee?.id,
              assigneeName: assignee?.name,
              clearAssignee: assignee == null,
            ),
          )
        : await model.createTask(
            eventId: widget.event.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            dueDate: _dueDate,
            priority: _priority,
            assigneeId: assignee?.id,
            assigneeName: assignee?.name,
          );

    if (ok) {
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(_isEditing ? 'Завдання оновлено' : 'Завдання створено'),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(model.errorMessage ?? 'Сталася помилка')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = context.watch<TasksModel>().isSaving;
    final options = _assigneeOptions(context.watch<EventsModel>());

    // Якщо виконавця видалили із заходу, скидаємо вибір.
    final selectedAssignee =
        options.any((a) => a.id == _assigneeId) ? _assigneeId : null;

    return FormDialogShell(
      icon: Icons.task_alt,
      title: _isEditing ? 'Редагувати завдання' : 'Додати завдання',
      subtitle: _isEditing
          ? 'Змініть деталі завдання'
          : 'Заповніть деталі нового завдання',
      isSaving: isSaving,
      onSave: () => _onSavePressed(options),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Назва завдання',
              controller: _titleController,
              enabled: !isSaving,
              suffixIcon: const Icon(Icons.label_outline),
              validator: (v) =>
                  Validators.required(v, 'Введіть назву завдання'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSaving,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Опис',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DateTimeField(
                    label: 'Строк виконання',
                    value: _dueDate,
                    enabled: !isSaving,
                    onChanged: (value) => setState(() => _dueDate = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: selectedAssignee,
                    decoration: const InputDecoration(labelText: 'Виконавець'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Не призначено'),
                      ),
                      for (final a in options)
                        DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text(
                            a.id == widget.event.organizerId
                                ? '${a.name} (організатор)'
                                : a.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) => setState(() => _assigneeId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Пріоритет',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _PrioritySelector(
              value: _priority,
              enabled: !isSaving,
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _priority.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_priorityIcon(_priority)} ${_priority.label} пріоритет',
                style: TextStyle(
                  color: _priority.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _priorityIcon(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return '↓';
    case TaskPriority.medium:
      return '—';
    case TaskPriority.high:
      return '↑';
  }
}

/// Три кнопки вибору пріоритету в один ряд, як на макеті S-10.
class _PrioritySelector extends StatelessWidget {
  final TaskPriority value;
  final bool enabled;
  final ValueChanged<TaskPriority> onChanged;

  const _PrioritySelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  static const _icons = {
    TaskPriority.low: Icons.arrow_downward,
    TaskPriority.medium: Icons.remove,
    TaskPriority.high: Icons.arrow_upward,
  };

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outlineVariant;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final priority in TaskPriority.values) ...[
            if (priority != TaskPriority.values.first)
              VerticalDivider(width: 1, color: border),
            Expanded(
              child: Material(
                color: priority == value
                    ? priority.color.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: InkWell(
                  onTap: enabled ? () => onChanged(priority) : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _icons[priority],
                        size: 16,
                        color: priority == value ? priority.color : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        priority.label,
                        style: TextStyle(
                          color: priority == value ? priority.color : null,
                          fontWeight: priority == value
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (priority == value) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, size: 16, color: priority.color),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
