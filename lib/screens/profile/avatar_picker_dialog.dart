import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/user_avatar.dart';

/// Результат вибору: url == null означає «видалити фото».
class AvatarChoice {
  final String? url;
  const AvatarChoice(this.url);
}

/// Діалог вибору фото профілю (FR-06): готові аватарки за HTTPS-посиланнями
/// або власне посилання з попереднім переглядом.
class AvatarPickerDialog extends StatefulWidget {
  final String? currentUrl;
  final String initials;

  const AvatarPickerDialog({
    super.key,
    required this.currentUrl,
    required this.initials,
  });

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  static const List<String> _presetUrls = [
    'https://api.dicebear.com/9.x/adventurer/png?seed=Olena&size=128',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Taras&size=128',
    'https://api.dicebear.com/9.x/avataaars/png?seed=Maria&size=128',
    'https://api.dicebear.com/9.x/avataaars/png?seed=Andrii&size=128',
    'https://api.dicebear.com/9.x/lorelei/png?seed=Sofia&size=128',
    'https://api.dicebear.com/9.x/notionists/png?seed=Ivan&size=128',
    'https://api.dicebear.com/9.x/bottts/png?seed=Volunteer&size=128',
    'https://api.dicebear.com/9.x/fun-emoji/png?seed=Hub&size=128',
  ];

  final _customUrlFormKey = GlobalKey<FormState>();
  final _customUrlController = TextEditingController();

  String? _selectedUrl;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.currentUrl;
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  void _onPreviewCustomUrl() {
    if (!_customUrlFormKey.currentState!.validate()) return;
    setState(() => _selectedUrl = _customUrlController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Фото профілю'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: UserAvatar(
                  photoUrl: _selectedUrl,
                  initials: widget.initials,
                  radius: 48,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Попередній перегляд', style: textTheme.bodySmall),
              ),
              const SizedBox(height: 24),
              Text('Оберіть готове зображення', style: textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final url in _presetUrls)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _selectedUrl = url),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedUrl == url
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: UserAvatar(
                          photoUrl: url,
                          initials: widget.initials,
                          radius: 28,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Або вставте власне посилання', style: textTheme.titleSmall),
              const SizedBox(height: 12),
              Form(
                key: _customUrlFormKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customUrlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'https://...',
                        ),
                        validator: Validators.httpsUrl,
                        onFieldSubmitted: (_) => _onPreviewCustomUrl(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton(
                        onPressed: _onPreviewCustomUrl,
                        child: const Text('Переглянути'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.currentUrl != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const AvatarChoice(null)),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Видалити фото'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: _selectedUrl == null || _selectedUrl == widget.currentUrl
              ? null
              : () => Navigator.of(context).pop(AvatarChoice(_selectedUrl)),
          child: const Text('Зберегти'),
        ),
      ],
    );
  }
}
