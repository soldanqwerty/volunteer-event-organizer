import 'package:flutter/foundation.dart';

import '../data/models/participant.dart';
import '../data/models/volunteer_event.dart';
import '../data/repositories/event_repository.dart';
import '../data/services/preferences_service.dart';

/// Фільтр за датою на екрані «Заходи». Згідно зі специфікацією лаб. №2,
/// «Мої заходи» вбудовано в цей самий випадний список.
enum EventDateFilter {
  all('Усі дати'),
  upcoming('Найближчі'),
  thisWeek('Найближчі 7 днів'),
  past('Минулі'),
  mine('Мої заходи');

  const EventDateFilter(this.label);
  final String label;
}

enum EventSort {
  dateAsc('Спочатку найближчі'),
  dateDesc('Спочатку пізніші'),
  title('За назвою');

  const EventSort(this.label);
  final String label;
}

/// Стан заходів та учасників (app state): завантаження списку, пошук,
/// фільтрація, сортування, створення, редагування, видалення, запис
/// на захід і керування заявками учасників.
class EventsModel extends ChangeNotifier {
  EventsModel({
    required this._repository,
    required this._preferences,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserEmail,
  });

  final EventRepository _repository;
  final PreferencesService _preferences;
  final String currentUserId;
  final String currentUserName;
  final String currentUserEmail;

  List<VolunteerEvent> _events = [];
  List<Participant> _participants = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  String _query = '';
  EventDateFilter _dateFilter = EventDateFilter.upcoming;
  EventCategory? _category;
  EventSort _sort = EventSort.dateAsc;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  EventDateFilter get dateFilter => _dateFilter;
  EventCategory? get category => _category;
  EventSort get sort => _sort;

  // ----------------------------------------------------- Завантаження

  /// Завантажує заходи й учасників та відновлює збережені фільтри.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _restoreFilters();
      // Обидва запити стартують одночасно, а не один за одним.
      final eventsFuture = _repository.fetchEvents();
      final participantsFuture = _repository.fetchParticipants();
      _events = List.of(await eventsFuture);
      _participants = List.of(await participantsFuture);
    } catch (_) {
      _errorMessage = 'Не вдалося завантажити заходи. Спробуйте ще раз.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreFilters() async {
    final savedDate = await _preferences.loadEventsDateFilter();
    final savedCategory = await _preferences.loadEventsCategory();
    final savedSort = await _preferences.loadEventsSort();

    _dateFilter = EventDateFilter.values.firstWhere(
      (f) => f.name == savedDate,
      orElse: () => EventDateFilter.upcoming,
    );
    _category = EventCategory.values
        .where((c) => c.name == savedCategory)
        .firstOrNull;
    _sort = EventSort.values.firstWhere(
      (s) => s.name == savedSort,
      orElse: () => EventSort.dateAsc,
    );
  }

  // --------------------------------------------- Обчислювані значення

  /// Список для екрана «Заходи» з урахуванням пошуку, фільтрів і сортування.
  List<VolunteerEvent> get visibleEvents {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    final query = _query.trim().toLowerCase();

    final result = _events.where((event) {
      if (query.isNotEmpty &&
          !event.title.toLowerCase().contains(query) &&
          !event.location.toLowerCase().contains(query)) {
        return false;
      }
      if (_category != null && event.category != _category) return false;

      switch (_dateFilter) {
        case EventDateFilter.all:
          return true;
        case EventDateFilter.upcoming:
          return !event.dateTime.isBefore(now);
        case EventDateFilter.thisWeek:
          return !event.dateTime.isBefore(now) &&
              event.dateTime.isBefore(weekLater);
        case EventDateFilter.past:
          return event.dateTime.isBefore(now);
        case EventDateFilter.mine:
          return isMyEvent(event);
      }
    }).toList();

    switch (_sort) {
      case EventSort.dateAsc:
        result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      case EventSort.dateDesc:
        result.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      case EventSort.title:
        result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }

  /// Найближчі майбутні заходи для головного екрана.
  List<VolunteerEvent> upcomingEvents({int limit = 3}) {
    final now = DateTime.now();
    final upcoming = _events.where((e) => !e.dateTime.isBefore(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.take(limit).toList();
  }

  VolunteerEvent? eventById(String id) =>
      _events.where((e) => e.id == id).firstOrNull;

  bool isOrganizer(VolunteerEvent event) => event.isOrganizedBy(currentUserId);

  /// Захід вважається «моїм», якщо я організатор або подав заявку,
  /// яку не відхилили.
  bool isMyEvent(VolunteerEvent event) {
    if (isOrganizer(event)) return true;
    final participation = myParticipation(event.id);
    return participation != null &&
        participation.status != ParticipantStatus.rejected;
  }

  List<Participant> participantsOf(String eventId) =>
      _participants.where((p) => p.eventId == eventId).toList();

  int confirmedCount(String eventId) => _participants
      .where(
        (p) => p.eventId == eventId && p.status == ParticipantStatus.confirmed,
      )
      .length;

  bool isFull(VolunteerEvent event) =>
      confirmedCount(event.id) >= event.participantLimit;

  Participant? myParticipation(String eventId) => _participants
      .where((p) => p.eventId == eventId && p.userId == currentUserId)
      .firstOrNull;

  // ------------------------------------------- Фільтри (зберігаються)

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setDateFilter(EventDateFilter value) {
    _dateFilter = value;
    notifyListeners();
    _preferences.saveEventsDateFilter(value.name);
  }

  void setCategory(EventCategory? value) {
    _category = value;
    notifyListeners();
    _preferences.saveEventsCategory(value?.name);
  }

  void setSort(EventSort value) {
    _sort = value;
    notifyListeners();
    _preferences.saveEventsSort(value.name);
  }

  // ------------------------------------------------------------ CRUD

  /// FR-08. Створення заходу; поточний користувач стає організатором.
  Future<bool> createEvent({
    required String title,
    required String description,
    required EventCategory category,
    required DateTime dateTime,
    required DateTime endDateTime,
    required String location,
    required int participantLimit,
  }) {
    return _save(() async {
      final created = await _repository.createEvent(
        VolunteerEvent(
          id: '',
          title: title,
          description: description,
          category: category,
          dateTime: dateTime,
          endDateTime: endDateTime,
          location: location,
          participantLimit: participantLimit,
          organizerId: currentUserId,
          organizerName: currentUserName,
        ),
      );
      _events.add(created);
    });
  }

  /// FR-10. Редагування заходу (лише організатор).
  Future<bool> updateEvent(VolunteerEvent event) {
    return _save(() async {
      final updated = await _repository.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == updated.id);
      if (index != -1) _events[index] = updated;
    });
  }

  /// FR-11. Видалення заходу разом з учасниками.
  Future<bool> deleteEvent(String eventId) {
    return _save(() async {
      await _repository.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      _participants.removeWhere((p) => p.eventId == eventId);
    });
  }

  // ----------------------------------------------- Участь у заході

  /// FR-12. Запис на захід — заявка зі статусом «Очікує підтвердження».
  Future<bool> joinEvent(VolunteerEvent event) {
    return _save(() async {
      final created = await _repository.addParticipant(
        Participant(
          id: '',
          eventId: event.id,
          userId: currentUserId,
          name: currentUserName,
          email: currentUserEmail,
          status: ParticipantStatus.pending,
        ),
      );
      _participants.add(created);
    });
  }

  /// FR-12. Скасування участі.
  Future<bool> leaveEvent(VolunteerEvent event) {
    final participation = myParticipation(event.id);
    if (participation == null) return Future.value(false);
    return _save(() async {
      await _repository.removeParticipant(participation.id);
      _participants.removeWhere((p) => p.id == participation.id);
    });
  }

  /// FR-13. Організатор підтверджує або відхиляє заявку.
  Future<bool> setParticipantStatus(
    Participant participant,
    ParticipantStatus status,
  ) {
    return _save(() async {
      final updated = await _repository.updateParticipant(
        participant.copyWith(status: status),
      );
      final index = _participants.indexWhere((p) => p.id == updated.id);
      if (index != -1) _participants[index] = updated;
    });
  }

  /// FR-13. Організатор видаляє учасника зі списку.
  Future<bool> removeParticipant(Participant participant) {
    return _save(() async {
      await _repository.removeParticipant(participant.id);
      _participants.removeWhere((p) => p.id == participant.id);
    });
  }

  /// Спільна обгортка для змін: стан збереження, блокування повторного
  /// надсилання та перехоплення помилки.
  Future<bool> _save(Future<void> Function() action) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (_) {
      _errorMessage = 'Не вдалося зберегти зміни. Спробуйте ще раз.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
