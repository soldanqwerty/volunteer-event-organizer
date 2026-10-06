import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { newTask, inProgress, done }

class TaskPreview {
  final String title;
  final String dueDate;
  final TaskPriority priority;
  final TaskStatus status;

  const TaskPreview({
    required this.title,
    required this.dueDate,
    required this.priority,
    required this.status,
  });
}

class TaskListTile extends StatelessWidget {
  final TaskPreview task;

  const TaskListTile({super.key, required this.task});

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case TaskStatus.newTask:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _statusLabel() {
    switch (task.status) {
      case TaskStatus.newTask:
        return 'Нове';
      case TaskStatus.inProgress:
        return 'У роботі';
      case TaskStatus.done:
        return 'Виконано';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(radius: 6, backgroundColor: _priorityColor()),
        title: Text(task.title),
        subtitle: Row(
          children: [
            const Icon(Icons.calendar_today, size: 12),
            const SizedBox(width: 4),
            Text(task.dueDate),
          ],
        ),
        trailing: Chip(
          label: Text(
            _statusLabel(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
          ),
          backgroundColor: statusColor.withOpacity(0.12),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
