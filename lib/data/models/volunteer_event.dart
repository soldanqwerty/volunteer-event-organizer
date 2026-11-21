import 'package:cloud_firestore/cloud_firestore.dart';
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
  /// Початок заходу.
  final DateTime dateTime;

  /// Завершення заходу (макет S-07: поля «Початок» і «Завершення»).
  final DateTime endDateTime;
  final String location;

  /// Максимальна кількість учасників (FR-08).
  final int participantLimit;

  /// Ідентифікатор організатора. Роль «організатор» не зберігається
  /// окремо, а обчислюється: currentUserId == organizerId.
  final String organizerId;
  final String organizerName;

  /// Посилання на обкладинку в Supabase Storage (необов'язкова, FR-08).
  final String? coverUrl;

  const VolunteerEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.endDateTime,
    required this.location,
    required this.participantLimit,
    required this.organizerId,
    required this.organizerName,
    this.coverUrl,
  });

  /// Документ колекції `events` → об'єкт. Дати в Firestore зберігаються
  /// як Timestamp, категорія — як назва значення enum.
  factory VolunteerEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return VolunteerEvent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: EventCategory.values.asNameMap()[data['category']] ??
          EventCategory.social,
      dateTime: (data['startAt'] as Timestamp).toDate(),
      endDateTime: (data['endAt'] as Timestamp).toDate(),
      location: data['location'] as String? ?? '',
      participantLimit: (data['participantLimit'] as num?)?.toInt() ?? 0,
      organizerId: data['organizerId'] as String? ?? '',
      organizerName: data['organizerName'] as String? ?? '',
      coverUrl: data['coverUrl'] as String?,
    );
  }

  /// Об'єкт → поля документа (id не зберігається: це ім'я документа).
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'category': category.name,
        'startAt': Timestamp.fromDate(dateTime),
        'endAt': Timestamp.fromDate(endDateTime),
        'location': location,
        'participantLimit': participantLimit,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'coverUrl': coverUrl,
      };

  bool isOrganizedBy(String? userId) => userId != null && userId == organizerId;

  bool get isPast => endDateTime.isBefore(DateTime.now());

  VolunteerEvent copyWith({
    String? title,
    String? description,
    EventCategory? category,
    DateTime? dateTime,
    DateTime? endDateTime,
    String? location,
    int? participantLimit,
    String? coverUrl,
    bool clearCover = false,
  }) {
    return VolunteerEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      participantLimit: participantLimit ?? this.participantLimit,
      organizerId: organizerId,
      organizerName: organizerName,
      coverUrl: clearCover ? null : (coverUrl ?? this.coverUrl),
    );
  }
}
