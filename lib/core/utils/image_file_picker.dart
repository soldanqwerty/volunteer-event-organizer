import 'package:file_picker/file_picker.dart';

import '../../data/repositories/storage_repository.dart';

/// Відкриває стандартне вікно вибору файлу та повертає зображення
/// (FR-06, FR-08). null — користувач нічого не обрав.
Future<PickedImage?> pickImageFile() async {
  // file_picker 13: статичний метод pickFile() для одного файлу.
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final name = file.name;
  final extension =
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
  final contentType = switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };

  return PickedImage(bytes: bytes, name: name, contentType: contentType);
}
