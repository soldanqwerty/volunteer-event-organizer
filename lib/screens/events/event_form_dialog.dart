import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/image_file_picker.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/date_time_field.dart';
import '../../core/widgets/form_dialog_shell.dart';
import '../../data/models/volunteer_event.dart';
import '../../data/repositories/storage_repository.dart';
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
  late DateTime _start;
  late DateTime _end;

  /// Обкладинка (лаб. №6): нове вибране фото або прапорець «прибрати».
  PickedImage? _newCover;
  bool _removeCover = false;
  String? _coverError;

  /// Помилка дат показується лише після спроби зберегти.
  bool _submitted = false;

  bool get _isEditing => widget.event != null;
  bool get _datesValid => _end.isAfter(_start);

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
    _start = event?.dateTime ??
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
    _end = event?.endDateTime ?? _start.add(const Duration(hours: 3));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _onStartChanged(DateTime value) {
    setState(() {
      // Зберігаємо тривалість заходу при зміні початку.
      final duration = _end.difference(_start);
      _start = value;
      _end = value.add(duration.isNegative ? Duration.zero : duration);
    });
  }

  Future<void> _onSavePressed() async {
    setState(() => _submitted = true);
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || !_datesValid) return;

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
              dateTime: _start,
              endDateTime: _end,
              location: _locationController.text.trim(),
              participantLimit: limit,
            ),
            newCover: _newCover,
            removeCover: _removeCover,
          )
        : await model.createEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            dateTime: _start,
            endDateTime: _end,
            location: _locationController.text.trim(),
            participantLimit: limit,
            cover: _newCover,
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

  /// FR-08. Вибір обкладинки: перевірка формату й розміру одразу після
  /// вибору, завантаження в сховище — під час збереження заходу.
  Future<void> _pickCover() async {
    final image = await pickImageFile();
    if (image == null) return;
    try {
      SupabaseStorageRepository.validate(image);
      setState(() {
        _newCover = image;
        _removeCover = false;
        _coverError = null;
      });
    } on StorageException catch (e) {
      setState(() => _coverError = e.message);
    }
  }

  void _clearCover() => setState(() {
        _newCover = null;
        _removeCover = true;
        _coverError = null;
      });

  @override
  Widget build(BuildContext context) {
    // watch: діалог перебудовується, коли змінюється isSaving.
    final isSaving = context.watch<EventsModel>().isSaving;

    return FormDialogShell(
      icon: Icons.event_note_outlined,
      title: _isEditing ? 'Редагувати захід' : 'Створити захід',
      subtitle: _isEditing
          ? 'Змініть інформацію про захід'
          : 'Заповніть інформацію про новий захід',
      isSaving: isSaving,
      onSave: _onSavePressed,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Назва заходу',
              controller: _titleController,
              enabled: !isSaving,
              suffixIcon: const Icon(Icons.label_outline),
              validator: (v) => Validators.required(v, 'Введіть назву заходу'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSaving,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Опис',
                alignLabelWithHint: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => Validators.required(v, 'Додайте опис'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Адреса',
              controller: _locationController,
              enabled: !isSaving,
              suffixIcon: const Icon(Icons.location_on_outlined),
              validator: (v) =>
                  Validators.required(v, 'Вкажіть адресу проведення'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DateTimeField(
                    label: 'Початок',
                    value: _start,
                    enabled: !isSaving,
                    onChanged: _onStartChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateTimeField(
                    label: 'Завершення',
                    value: _end,
                    enabled: !isSaving,
                    errorText: _submitted && !_datesValid
                        ? 'Має бути пізніше за початок'
                        : null,
                    onChanged: (value) => setState(() => _end = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Ліміт учасників',
                    controller: _limitController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    suffixIcon: const Icon(Icons.group_outlined),
                    validator: Validators.positiveInt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Від категорії залежить колір обкладинки за замовчуванням.
                  child: DropdownButtonFormField<EventCategory>(
                    isExpanded: true,
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Категорія'),
                    items: [
                      for (final category in EventCategory.values)
                        DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 5,
                                backgroundColor: category.color,
                              ),
                              const SizedBox(width: 8),
                              Text(category.label),
                            ],
                          ),
                        ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) => setState(() => _category = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CoverField(
              newCover: _newCover,
              existingUrl: _removeCover ? null : widget.event?.coverUrl,
              error: _coverError,
              enabled: !isSaving,
              onPick: _pickCover,
              onClear: _clearCover,
            ),
          ],
        ),
      ),
    );
  }
}

/// Поле «Обкладинка» з макета S-07: попередній перегляд і кнопки.
class _CoverField extends StatelessWidget {
  final PickedImage? newCover;
  final String? existingUrl;
  final String? error;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _CoverField({
    required this.newCover,
    required this.existingUrl,
    required this.error,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = newCover != null || existingUrl != null;

    Widget preview;
    if (newCover != null) {
      preview = Image.memory(newCover!.bytes, fit: BoxFit.cover);
    } else if (existingUrl != null) {
      preview = Image.network(existingUrl!, fit: BoxFit.cover);
    } else {
      preview = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 32, color: colorScheme.primary),
          const SizedBox(height: 6),
          const Text('Обкладинка заходу'),
          Text(
            'JPEG, PNG або WebP, до 5 МБ',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: enabled ? onPick : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? colorScheme.error : colorScheme.outline,
              ),
            ),
            child: preview,
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: enabled ? onPick : null,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(hasImage ? 'Замінити фото' : 'Обрати фото'),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Прибрати'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
