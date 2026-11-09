import 'package:flutter/material.dart';

import '../../data/models/volunteer_event.dart';
import '../utils/date_formatter.dart';
import 'event_cover.dart';
import 'status_pill.dart';

/// Компактна горизонтальна картка заходу для головного екрана (S-04):
/// обкладинка ліворуч, дата, назва, час і місце праворуч.
class EventCompactCard extends StatelessWidget {
  final VolunteerEvent event;
  final VoidCallback? onTap;

  const EventCompactCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 92,
              child: EventCover(
                category: event.category,
                iconSize: 32,
                topLeft: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: event.category.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.dayMonth(event.dateTime).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconLine(
                      icon: Icons.access_time,
                      text: DateFormatter.time(event.dateTime),
                    ),
                    const SizedBox(height: 4),
                    IconLine(
                      icon: Icons.location_on_outlined,
                      text: event.location,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Картка заходу для сітки на екрані «Заходи» (S-05): обкладинка з
/// категорією, мітка реєстрації, назва, дата, адреса, кількість
/// учасників і посилання «Детальніше».
class EventListCard extends StatelessWidget {
  final VolunteerEvent event;
  final int confirmedCount;
  final bool isOrganizer;
  final VoidCallback? onTap;

  const EventListCard({
    super.key,
    required this.event,
    required this.confirmedCount,
    required this.isOrganizer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = RegistrationBadge.of(event, confirmedCount);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 150,
              child: EventCover(
                category: event.category,
                topLeft: StatusPill(
                  label: event.category.label,
                  color: event.category.color,
                  onImage: true,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: [
                        StatusPill(label: badge.label, color: badge.color),
                        if (isOrganizer)
                          StatusPill(
                            label: 'Ви організатор',
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    IconLine(
                      icon: Icons.schedule,
                      text: DateFormatter.dayMonthTimeRange(
                        event.dateTime,
                        event.endDateTime,
                      ),
                      bold: true,
                    ),
                    const SizedBox(height: 4),
                    IconLine(
                      icon: Icons.location_on_outlined,
                      text: event.location,
                    ),
                    const Spacer(),
                    const Divider(height: 1),
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$confirmedCount/${event.participantLimit} учасників',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: onTap,
                          child: const Text('Детальніше'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Рядок «іконка + текст» у картках і деталях заходу.
class IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;

  const IconLine({
    super.key,
    required this.icon,
    required this.text,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
