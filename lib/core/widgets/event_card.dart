import 'package:flutter/material.dart';

import '../../data/models/volunteer_event.dart';
import '../utils/date_formatter.dart';

/// Картка заходу для головного екрана та сітки на екрані «Заходи».
class EventCard extends StatelessWidget {
  final VolunteerEvent event;
  final VoidCallback? onTap;

  /// Підпис під назвою, наприклад «8/20 учасників» або «Ви організатор».
  final String? footnote;
  final double? width;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.footnote,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: event.category.color.withValues(alpha: 0.12),
                  child: Icon(
                    _categoryIcon(event.category),
                    size: 36,
                    color: event.category.color,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: event.category.color,
                  ),
                ),
                if (event.isPast)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Chip(
                      label: const Text('Завершено'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: textTheme.labelSmall,
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormatter.dayMonth(event.dateTime).toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _IconLine(
                    icon: Icons.access_time,
                    text: DateFormatter.time(event.dateTime),
                  ),
                  const SizedBox(height: 4),
                  _IconLine(
                    icon: Icons.location_on_outlined,
                    text: event.location,
                  ),
                  if (footnote != null) ...[
                    const SizedBox(height: 4),
                    _IconLine(icon: Icons.group_outlined, text: footnote!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }

  static IconData _categoryIcon(EventCategory category) {
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
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
