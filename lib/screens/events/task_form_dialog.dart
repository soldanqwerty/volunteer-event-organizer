import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/date_time_field.dart';
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
    final isSaving = context.watch<TasksModel>().isSaving;
    final options = _assigneeOptions(context.watch<EventsModel>());

    // Якщо виконавця видалили із заходу, скидаємо вибір.
    final selectedAssignee =
        options.any((a) => a.id == _assigneeId) ? _assigneeId : null;

    return AlertDialog(
      title: Text(_isEditing ? 'Редагування завдання' : 'Нове завдання'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Назва завдання',
                  controller: _titleController,
                  enabled: !isSaving,
                  validator: (v) =>
                      Validators.required(v, 'Введіть назву завдання'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !isSaving,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Опис (необов'язково)",
                  ),
                ),
                const SizedBox(height: 16),
                DateTimeField(
                  label: 'Термін виконання',
                  value: _dueDate,
                  enabled: !isSaving,
                  onChanged: (value) => setState(() => _dueDate = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Пріоритет'),
                  items: [
                    for (final priority in TaskPriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 5,
                              backgroundColor: priority.color,
                            ),
                            const SizedBox(width: 8),
                            Text(priority.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _priority = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
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
                        ),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _assigneeId = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: isSaving ? null : () => _onSavePressed(options),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Зберегти' : 'Створити'),
        ),
      ],
    );
  }
}
