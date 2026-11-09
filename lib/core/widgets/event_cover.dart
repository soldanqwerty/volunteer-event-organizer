import 'package:flutter/material.dart';

import '../../data/models/volunteer_event.dart';

/// Стан реєстрації на захід — мітка на картці (макети S-05, S-06).
enum RegistrationBadge {
  open('Реєстрація', Color(0xFF2E7D32)),
  soon('Скоро', Color(0xFFE08600)),
  almostFull('Майже повний', Color(0xFFC62828)),
  full('Місць немає', Color(0xFFC62828)),
  finished('Завершено', Color(0xFF616161));

  const RegistrationBadge(this.label, this.color);
  final String label;
  final Color color;

  /// Обчислюється з дати заходу та кількості підтверджених учасників.
  static RegistrationBadge of(VolunteerEvent event, int confirmed) {
    if (event.isPast) return finished;
    if (confirmed >= event.participantLimit) return full;
    if (confirmed >= event.participantLimit * 0.8) return almostFull;
    if (event.dateTime.difference(DateTime.now()).inDays < 7) return soon;
    return open;
  }
}

/// «Обкладинка» заходу. Фото ще не завантажуються (з'являться разом
/// зі сховищем файлів), тому замість фото — градієнт кольору категорії
/// з великою іконкою.
class EventCover extends StatelessWidget {
  final EventCategory category;
  final double iconSize;

  /// Мітки поверх обкладинки, наприклад категорія чи «Реєстрація відкрита».
  final Widget? topLeft;
  final Widget? bottomLeft;
  final BorderRadius borderRadius;

  const EventCover({
    super.key,
    required this.category,
    this.iconSize = 48,
    this.topLeft,
    this.bottomLeft,
    this.borderRadius = BorderRadius.zero,
  });

  static IconData iconOf(EventCategory category) {
    switch (category) {
      case EventCategory.ecology:
        return Icons.park_outlined;
      case EventCategory.social:
        return Icons.volunteer_activism_outlined;
      case EventCategory.animals:
        return Icons.pets_outlined;
      case EventCategory.education:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Icon(
              iconOf(category),
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (topLeft != null) Positioned(top: 8, left: 8, child: topLeft!),
          if (bottomLeft != null)
            Positioned(bottom: 8, left: 8, child: bottomLeft!),
        ],
      ),
    );
  }
}
