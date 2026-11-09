import 'package:flutter/material.dart';

/// Статус заявки учасника на захід.
enum ParticipantStatus {
  pending('Очікує підтвердження', Colors.orange),
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

  const Participant({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.name,
    required this.email,
    required this.status,
  });

  Participant copyWith({ParticipantStatus? status}) {
    return Participant(
      id: id,
      eventId: eventId,
      userId: userId,
      name: name,
      email: email,
      status: status ?? this.status,
    );
  }
}
