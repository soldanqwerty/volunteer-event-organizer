import 'package:file_picker/file_picker.dart';

import '../../data/repositories/storage_repository.dart';

/// Відкриває стандартне вікно вибору файлу та повертає зображення
/// (FR-06, FR-08). null — користувач нічого не обрав.
Future<PickedImage?> pickImageFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    withData: true, // на вебі файл доступний лише як байти
  );
  final file = result?.files.singleOrNull;
  if (file == null || file.bytes == null) return null;

  final extension = (file.extension ?? '').toLowerCase();
  final contentType = switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };

  return PickedImage(
    bytes: file.bytes!,
    name: file.name,
    contentType: contentType,
  );
}
