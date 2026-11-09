import 'package:flutter/material.dart';

/// Категорія заходу. Від неї залежить колір позначки на картці.
enum EventCategory {
  ecology('Екологія', Colors.green),
  social('Соціальна допомога', Colors.orange),
  animals('Тварини', Colors.purple),
  education('Освіта', Colors.blue);

  const EventCategory(this.label, this.color);

  final String label;
  final Color color;
}

/// Об'єкт даних «Захід» (специфікація лаб. №2).
///
/// Клас незмінний (immutable): щоб змінити захід, створюється нова копія
/// через [copyWith]. Так провайдер завжди отримує новий об'єкт і віджети
/// гарантовано перебудовуються.
class VolunteerEvent {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime dateTime;
  final String location;

  /// Максимальна кількість учасників (FR-08).
  final int participantLimit;

  /// Ідентифікатор організатора. Роль «організатор» не зберігається
  /// окремо, а обчислюється: currentUserId == organizerId.
  final String organizerId;
  final String organizerName;

  const VolunteerEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    required this.participantLimit,
    required this.organizerId,
    required this.organizerName,
  });

  bool isOrganizedBy(String? userId) => userId != null && userId == organizerId;

  bool get isPast => dateTime.isBefore(DateTime.now());

  VolunteerEvent copyWith({
    String? title,
    String? description,
    EventCategory? category,
    DateTime? dateTime,
    String? location,
    int? participantLimit,
  }) {
    return VolunteerEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      participantLimit: participantLimit ?? this.participantLimit,
      organizerId: organizerId,
      organizerName: organizerName,
    );
  }
}
