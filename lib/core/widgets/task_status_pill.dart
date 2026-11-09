import 'package:flutter/material.dart';

import '../../data/models/event_task.dart';
import 'status_pill.dart';

/// Мітка статусу завдання; якщо задано [onChanged], по кліку
/// відкривається меню зміни статусу.
class TaskStatusPill extends StatelessWidget {
  final EventTask task;
  final ValueChanged<TaskStatus>? onChanged;

  const TaskStatusPill({super.key, required this.task, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pill = StatusPill(
      label: task.status.label,
      color: task.status.color,
      icon: onChanged == null ? null : Icons.expand_more,
    );
    if (onChanged == null) return pill;

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
      child: pill,
    );
  }
}
