import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Пріоритет завдання.
enum TaskPriority {
  low('Низький', Colors.green),
  medium('Середній', Colors.orange),
  high('Високий', Colors.red);

  const TaskPriority(this.label, this.color);

  final String label;
  final Color color;
}

/// Статус виконання завдання.
enum TaskStatus {
  newTask('Нове', Color(0xFF2E7D32)),
  inProgress('У роботі', Color(0xFFB7791F)),
  done('Виконано', Color(0xFF616161));

  const TaskStatus(this.label, this.color);

  final String label;
  final Color color;
}

/// Об'єкт даних «Завдання» — робота в межах заходу, призначена учаснику.
class EventTask {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;

  /// Виконавець (null — завдання ще не розподілене).
  final String? assigneeId;
  final String? assigneeName;

  const EventTask({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.assigneeId,
    this.assigneeName,
  });

  /// Документ підколекції `events/{eventId}/tasks/{taskId}`.
  factory EventTask.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return EventTask(
      id: doc.id,
      eventId: data['eventId'] as String,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      priority: TaskPriority.values.asNameMap()[data['priority']] ??
          TaskPriority.medium,
      status: TaskStatus.values.asNameMap()[data['status']] ??
          TaskStatus.newTask,
      assigneeId: data['assigneeId'] as String?,
      assigneeName: data['assigneeName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'eventId': eventId,
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'priority': priority.name,
        'status': status.name,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
      };

  /// [clearAssignee] потрібен, бо через copyWith(assigneeId: null)
  /// неможливо відрізнити «не змінювати» від «прибрати виконавця».
  EventTask copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? assigneeId,
    String? assigneeName,
    bool clearAssignee = false,
  }) {
    return EventTask(
      id: id,
      eventId: eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      assigneeName: clearAssignee ? null : (assigneeName ?? this.assigneeName),
    );
  }
}
