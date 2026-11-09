import 'package:flutter/foundation.dart';

import '../data/models/event_task.dart';
import '../data/repositories/event_repository.dart';
import '../data/services/preferences_service.dart';

/// Сортування на екрані «Мої завдання».
enum TaskSort {
  dueDate('За терміном'),
  priority('За пріоритетом');

  const TaskSort(this.label);
  final String label;
}

/// Стан завдань (app state): завантаження, фільтр за статусом,
/// створення, редагування, розподіл, зміна статусу та видалення
/// (FR-14 – FR-17).
class TasksModel extends ChangeNotifier {
  TasksModel({
    required this._repository,
    required this._preferences,
    required this.currentUserId,
  });

  final EventRepository _repository;
  final PreferencesService _preferences;
  final String currentUserId;

  List<EventTask> _tasks = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  /// null — показувати всі статуси.
  TaskStatus? _statusFilter;
  TaskSort _sort = TaskSort.dueDate;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  TaskStatus? get statusFilter => _statusFilter;
  TaskSort get sort => _sort;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedStatus = await _preferences.loadTasksStatusFilter();
      _statusFilter =
          TaskStatus.values.where((s) => s.name == savedStatus).firstOrNull;
      _tasks = List.of(await _repository.fetchTasks());
    } catch (_) {
      _errorMessage = 'Не вдалося завантажити завдання. Спробуйте ще раз.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------- Обчислювані значення

  /// Завдання конкретного заходу (вкладка «Завдання» на екрані деталей).
  List<EventTask> tasksOf(String eventId) =>
      _tasks.where((t) => t.eventId == eventId).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  /// Завдання поточного користувача з урахуванням фільтра й сортування.
  List<EventTask> get myTasks {
    final result = _tasks
        .where((t) => t.assigneeId == currentUserId)
        .where((t) => _statusFilter == null || t.status == _statusFilter)
        .toList();

    switch (_sort) {
      case TaskSort.dueDate:
        result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      case TaskSort.priority:
        // Високий пріоритет першим.
        result.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    }
    return result;
  }

  /// Невиконані завдання для головного екрана.
  List<EventTask> get myActiveTasks => _tasks
      .where((t) => t.assigneeId == currentUserId)
      .where((t) => t.status != TaskStatus.done)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  int countMyTasksWithStatus(TaskStatus status) => _tasks
      .where((t) => t.assigneeId == currentUserId && t.status == status)
      .length;

  // ------------------------------------------- Фільтри (зберігаються)

  void setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    notifyListeners();
    _preferences.saveTasksStatusFilter(status?.name);
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    notifyListeners();
  }

  // ------------------------------------------------------------ CRUD

  /// FR-14. Створення завдання з необов'язковим виконавцем.
  Future<bool> createTask({
    required String eventId,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskPriority priority,
    String? assigneeId,
    String? assigneeName,
  }) {
    return _save(() async {
      final created = await _repository.createTask(
        EventTask(
          id: '',
          eventId: eventId,
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          status: TaskStatus.newTask,
          assigneeId: assigneeId,
          assigneeName: assigneeName,
        ),
      );
      _tasks.add(created);
    });
  }

  /// FR-14, FR-15. Редагування та розподіл (зміна виконавця).
  Future<bool> updateTask(EventTask task) {
    return _save(() async {
      final updated = await _repository.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) _tasks[index] = updated;
    });
  }

  /// FR-16. Зміна статусу (виконавець або організатор).
  Future<bool> changeStatus(EventTask task, TaskStatus status) =>
      updateTask(task.copyWith(status: status));

  /// FR-17.
  Future<bool> deleteTask(String taskId) {
    return _save(() async {
      await _repository.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
    });
  }

  /// Після видалення заходу репозиторій уже видалив його завдання,
  /// тут лише синхронізуємо локальний стан.
  void removeTasksOfEvent(String eventId) {
    _tasks.removeWhere((t) => t.eventId == eventId);
    notifyListeners();
  }

  Future<bool> _save(Future<void> Function() action) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (_) {
      _errorMessage = 'Не вдалося зберегти завдання. Спробуйте ще раз.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
