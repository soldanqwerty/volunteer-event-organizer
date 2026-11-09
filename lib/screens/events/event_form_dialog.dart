import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/date_time_field.dart';
import '../../data/models/volunteer_event.dart';
import '../../state/events_model.dart';

/// Відкриває форму заходу (макет S-07). [event] == null — створення,
/// інакше — редагування. Повертає true, якщо захід збережено.
Future<bool> showEventFormDialog(
  BuildContext context, {
  VolunteerEvent? event,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => EventFormDialog(event: event),
  );
  return saved ?? false;
}

/// Форма створення та редагування заходу (FR-08, FR-10).
///
/// Значення полів — ефемерний стан діалогу (StatefulWidget), а
/// збереження та стан «зберігається…» — спільний стан [EventsModel].
class EventFormDialog extends StatefulWidget {
  final VolunteerEvent? event;

  const EventFormDialog({super.key, this.event});

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _limitController;
  late EventCategory _category;
  late DateTime _dateTime;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _limitController = TextEditingController(
      text: (event?.participantLimit ?? 10).toString(),
    );
    _category = event?.category ?? EventCategory.ecology;
    _dateTime = event?.dateTime ??
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    final model = context.read<EventsModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final limit = int.parse(_limitController.text.trim());

    final ok = _isEditing
        ? await model.updateEvent(
            widget.event!.copyWith(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: _category,
              dateTime: _dateTime,
              location: _locationController.text.trim(),
              participantLimit: limit,
            ),
          )
        : await model.createEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            dateTime: _dateTime,
            location: _locationController.text.trim(),
            participantLimit: limit,
          );

    if (ok) {
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Захід оновлено' : 'Захід створено'),
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
    // watch: діалог перебудовується, коли змінюється isSaving.
    final isSaving = context.watch<EventsModel>().isSaving;

    return AlertDialog(
      title: Text(_isEditing ? 'Редагування заходу' : 'Новий захід'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Назва заходу',
                  controller: _titleController,
                  enabled: !isSaving,
                  validator: (v) =>
                      Validators.required(v, 'Введіть назву заходу'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !isSaving,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Опис'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => Validators.required(v, 'Додайте опис'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EventCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Категорія'),
                  items: [
                    for (final category in EventCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 16),
                DateTimeField(
                  label: 'Дата і час',
                  value: _dateTime,
                  enabled: !isSaving,
                  onChanged: (value) => setState(() => _dateTime = value),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Місце проведення',
                  controller: _locationController,
                  enabled: !isSaving,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  validator: (v) =>
                      Validators.required(v, 'Вкажіть місце проведення'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Ліміт учасників',
                  controller: _limitController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.group_outlined),
                  validator: Validators.positiveInt,
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
          onPressed: isSaving ? null : _onSavePressed,
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
