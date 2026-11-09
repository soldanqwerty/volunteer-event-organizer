import 'package:flutter/material.dart';

import '../../data/models/event_task.dart';
import '../utils/date_formatter.dart';

/// Рядок завдання: пріоритет (кольорова крапка), назва, термін,
/// виконавець і статус.
class TaskListTile extends StatelessWidget {
  final EventTask task;
  final VoidCallback? onTap;

  /// Додатковий рядок, наприклад назва заходу на екрані «Мої завдання».
  final String? subtitle;
  final bool showAssignee;

  /// Якщо задано, статус можна змінити через випадне меню.
  final ValueChanged<TaskStatus>? onStatusChanged;
  final Widget? trailingAction;

  const TaskListTile({
    super.key,
    required this.task,
    this.onTap,
    this.subtitle,
    this.showAssignee = false,
    this.onStatusChanged,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOverdue =
        task.status != TaskStatus.done && task.dueDate.isBefore(DateTime.now());

    final details = <String>[
      DateFormatter.relativeDay(task.dueDate),
      ?subtitle,
      if (showAssignee) task.assigneeName ?? 'Не призначено',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Tooltip(
          message: 'Пріоритет: ${task.priority.label}',
          child: CircleAvatar(radius: 6, backgroundColor: task.priority.color),
        ),
        title: Text(
          task.title,
          style: task.status == TaskStatus.done
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: isOverdue ? Colors.red : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                details.join('  •  '),
                overflow: TextOverflow.ellipsis,
                style: isOverdue
                    ? textTheme.bodySmall?.copyWith(color: Colors.red)
                    : null,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusChip(task: task, onChanged: onStatusChanged),
            ?trailingAction,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final EventTask task;
  final ValueChanged<TaskStatus>? onChanged;

  const _StatusChip({required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = task.status.color;
    final chip = Chip(
      label: Text(
        task.status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      avatar: onChanged == null
          ? null
          : Icon(Icons.arrow_drop_down, color: color, size: 18),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
    );

    if (onChanged == null) return chip;

    return PopupMenuButton<TaskStatus>(
      tooltip: 'Змінити статус',
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final status in TaskStatus.values)
          CheckedPopupMenuItem(
            value: status,
            checked: status == task.status,
            child: Text(status.label),
          ),
      ],
      child: chip,
    );
  }
}
