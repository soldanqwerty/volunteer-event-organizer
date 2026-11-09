import '../mock/mock_data.dart';
import '../models/event_task.dart';
import '../models/participant.dart';
import '../models/volunteer_event.dart';

/// Контракт доступу до заходів, учасників і завдань.
///
/// Провайдери працюють з інтерфейсом, а не з реалізацією. У наступних
/// лабораторних [InMemoryEventRepository] буде замінено на реалізацію
/// з Cloud Firestore — без змін у провайдерах і екранах.
abstract interface class EventRepository {
  Future<List<VolunteerEvent>> fetchEvents();
  Future<VolunteerEvent> createEvent(VolunteerEvent draft);
  Future<VolunteerEvent> updateEvent(VolunteerEvent event);
  Future<void> deleteEvent(String eventId);

  Future<List<Participant>> fetchParticipants();
  Future<Participant> addParticipant(Participant participant);
  Future<Participant> updateParticipant(Participant participant);
  Future<void> removeParticipant(String participantId);

  Future<List<EventTask>> fetchTasks();
  Future<EventTask> createTask(EventTask draft);
  Future<EventTask> updateTask(EventTask task);
  Future<void> deleteTask(String taskId);
}

/// Тимчасова реалізація: дані зберігаються в пам'яті, а затримка
/// імітує запит до сервера, щоб на екранах було видно стан завантаження.
class InMemoryEventRepository implements EventRepository {
  InMemoryEventRepository({
    required String currentUserId,
    required String currentUserName,
    required String currentUserEmail,
  })  : _events = MockData.events(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
        ),
        _participants = MockData.participants(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          currentUserEmail: currentUserEmail,
        ),
        _tasks = MockData.tasks(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
        );

  static const _latency = Duration(milliseconds: 600);

  final List<VolunteerEvent> _events;
  final List<Participant> _participants;
  final List<EventTask> _tasks;
  int _idCounter = 100;

  String _nextId(String prefix) => '$prefix${_idCounter++}';

  // ---------------------------------------------------------------- Заходи

  @override
  Future<List<VolunteerEvent>> fetchEvents() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_events);
  }

  @override
  Future<VolunteerEvent> createEvent(VolunteerEvent draft) async {
    await Future.delayed(_latency);
    final created = VolunteerEvent(
      id: _nextId('e'),
      title: draft.title,
      description: draft.description,
      category: draft.category,
      dateTime: draft.dateTime,
      endDateTime: draft.endDateTime,
      location: draft.location,
      participantLimit: draft.participantLimit,
      organizerId: draft.organizerId,
      organizerName: draft.organizerName,
    );
    _events.add(created);
    return created;
  }

  @override
  Future<VolunteerEvent> updateEvent(VolunteerEvent event) async {
    await Future.delayed(_latency);
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index == -1) throw StateError('Захід не знайдено');
    _events[index] = event;
    return event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await Future.delayed(_latency);
    _events.removeWhere((e) => e.id == eventId);
    // Каскадне видалення пов'язаних даних.
    _participants.removeWhere((p) => p.eventId == eventId);
    _tasks.removeWhere((t) => t.eventId == eventId);
  }

  // ------------------------------------------------------------- Учасники

  @override
  Future<List<Participant>> fetchParticipants() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_participants);
  }

  @override
  Future<Participant> addParticipant(Participant participant) async {
    await Future.delayed(_latency);
    final created = Participant(
      id: _nextId('p'),
      eventId: participant.eventId,
      userId: participant.userId,
      name: participant.name,
      email: participant.email,
      status: participant.status,
    );
    _participants.add(created);
    return created;
  }

  @override
  Future<Participant> updateParticipant(Participant participant) async {
    await Future.delayed(_latency);
    final index = _participants.indexWhere((p) => p.id == participant.id);
    if (index == -1) throw StateError('Учасника не знайдено');
    _participants[index] = participant;
    return participant;
  }

  @override
  Future<void> removeParticipant(String participantId) async {
    await Future.delayed(_latency);
    _participants.removeWhere((p) => p.id == participantId);
  }

  // ------------------------------------------------------------- Завдання

  @override
  Future<List<EventTask>> fetchTasks() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_tasks);
  }

  @override
  Future<EventTask> createTask(EventTask draft) async {
    await Future.delayed(_latency);
    final created = EventTask(
      id: _nextId('t'),
      eventId: draft.eventId,
      title: draft.title,
      description: draft.description,
      dueDate: draft.dueDate,
      priority: draft.priority,
      status: draft.status,
      assigneeId: draft.assigneeId,
      assigneeName: draft.assigneeName,
    );
    _tasks.add(created);
    return created;
  }

  @override
  Future<EventTask> updateTask(EventTask task) async {
    await Future.delayed(_latency);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) throw StateError('Завдання не знайдено');
    _tasks[index] = task;
    return task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await Future.delayed(_latency);
    _tasks.removeWhere((t) => t.id == taskId);
  }
}
