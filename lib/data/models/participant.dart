import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Статус заявки учасника на захід.
enum ParticipantStatus {
  pending('Очікує', Colors.orange),
  confirmed('Підтверджено', Colors.green),
  rejected('Відхилено', Colors.red);

  const ParticipantStatus(this.label, this.color);

  final String label;
  final Color color;
}

/// Об'єкт даних «Учасник» — зв'язок користувача із заходом.
class Participant {
  final String id;
  final String eventId;
  final String userId;
  final String name;
  final String email;
  final ParticipantStatus status;

  /// Дата запису на захід (специфікація лаб. №2).
  final DateTime? joinedAt;

  const Participant({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.name,
    required this.email,
    required this.status,
    this.joinedAt,
  });

  /// Документ підколекції `events/{eventId}/participants/{userId}`.
  /// Ім'я документа — uid учасника, тому один користувач не може
  /// записатися на той самий захід двічі. Локальний id складений із
  /// заходу й користувача, щоб бути унікальним серед усіх заходів.
  factory Participant.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final eventId = data['eventId'] as String;
    final userId = data['userId'] as String;
    return Participant(
      id: '${eventId}_$userId',
      eventId: eventId,
      userId: userId,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      status: ParticipantStatus.values.asNameMap()[data['status']] ??
          ParticipantStatus.pending,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'eventId': eventId,
        'userId': userId,
        'name': name,
        'email': email,
        'status': status.name,
        'joinedAt': joinedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(joinedAt!),
      };

  Participant copyWith({ParticipantStatus? status}) {
    return Participant(
      id: id,
      eventId: eventId,
      userId: userId,
      name: name,
      email: email,
      status: status ?? this.status,
      joinedAt: joinedAt,
    );
  }
}
