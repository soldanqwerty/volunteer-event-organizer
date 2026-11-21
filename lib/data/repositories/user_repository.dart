import 'package:cloud_firestore/cloud_firestore.dart';

/// Профіль користувача в колекції `users/{uid}` (специфікація лаб. №2:
/// ім'я, прізвище, email, телефон, посилання на фото). Пароль тут не зберігається:
/// ним керує Firebase Authentication.
abstract interface class UserRepository {
  /// Телефон із документа профілю (FR-04); null, якщо його ще немає.
  Future<String?> fetchPhone(String uid);

  Future<void> saveProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? photoUrl,
    bool clearPhoto = false,
  });
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<String?> fetchPhone(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['phone'] as String?;
  }

  /// set(..., merge: true) створює документ, якщо його ще немає,
  /// і оновлює лише передані поля, якщо він уже є.
  @override
  Future<void> saveProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? photoUrl,
    bool clearPhoto = false,
  }) {
    return _db.collection('users').doc(uid).set({
      'firstName': ?firstName,
      'lastName': ?lastName,
      'email': ?email,
      'phone': ?phone,
      if (photoUrl != null || clearPhoto) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
