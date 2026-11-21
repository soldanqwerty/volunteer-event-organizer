import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, StorageFileApi, Supabase, SupabaseClient;

import '../../core/config/supabase_config.dart';

/// Помилка завантаження файлу з текстом для користувача.
class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => message;
}

/// Вибране користувачем зображення: байти, ім'я та MIME-тип.
class PickedImage {
  final Uint8List bytes;
  final String name;
  final String contentType;

  const PickedImage({
    required this.bytes,
    required this.name,
    required this.contentType,
  });
}

/// Хмарне файлове сховище (лаб. №6, завдання 8).
abstract interface class StorageRepository {
  /// Завантажує зображення в [folder] і повертає публічне посилання.
  Future<String> uploadImage(PickedImage image, {required String folder});

  /// Видаляє файл за публічним посиланням (якщо воно з нашого сховища).
  Future<void> deleteByUrl(String url);
}

/// Реалізація на Supabase Storage: публічний bucket `images`.
class SupabaseStorageRepository implements StorageRepository {
  SupabaseStorageRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const maxBytes = 5 * 1024 * 1024; // FR-06: до 5 МБ
  static const allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};

  StorageFileApi get _bucket => _client.storage.from(SupabaseConfig.bucket);

  /// FR-06: перевірка формату (JPEG, PNG, WebP) і розміру (до 5 МБ).
  static void validate(PickedImage image) {
    if (!allowedTypes.contains(image.contentType)) {
      throw const StorageException('Дозволені формати: JPEG, PNG, WebP');
    }
    if (image.bytes.lengthInBytes > maxBytes) {
      throw const StorageException('Розмір файлу не повинен перевищувати 5 МБ');
    }
  }

  @override
  Future<String> uploadImage(
    PickedImage image, {
    required String folder,
  }) async {
    validate(image);
    final extension = image.contentType.split('/').last;
    // Унікальне ім'я файлу: папка/час_у_мілісекундах.розширення.
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}.$extension';
    try {
      await _bucket.uploadBinary(
        path,
        image.bytes,
        fileOptions: FileOptions(contentType: image.contentType),
      );
      return _bucket.getPublicUrl(path);
    } catch (_) {
      throw const StorageException('Не вдалося завантажити файл');
    }
  }

  @override
  Future<void> deleteByUrl(String url) async {
    final marker = '/object/public/${SupabaseConfig.bucket}/';
    final index = url.indexOf(marker);
    if (index == -1) return; // не наш файл (наприклад, готовий аватар)
    final path = url.substring(index + marker.length);
    try {
      await _bucket.remove([path]);
    } catch (_) {
      // Видалення старого файлу не критичне для користувача.
    }
  }
}
