import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_event_organizer/data/models/volunteer_event.dart';
import 'package:volunteer_event_organizer/data/repositories/event_repository.dart';
import 'package:volunteer_event_organizer/data/services/preferences_service.dart';
import 'package:volunteer_event_organizer/state/events_model.dart';

/// Тести EventsModel без Firebase: дані беруться з in-memory репозиторію,
/// а SharedPreferences замінено тестовою реалізацією.
void main() {
  late EventsModel model;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    model = EventsModel(
      repository: InMemoryEventRepository(
        currentUserId: 'me',
        currentUserName: 'Тестовий Волонтер',
        currentUserEmail: 'me@test.com',
      ),
      preferences: PreferencesService(),
      currentUserId: 'me',
      currentUserName: 'Тестовий Волонтер',
      currentUserEmail: 'me@test.com',
    );
    await model.load();
  });

  test('завантажує заходи', () {
    expect(model.isLoading, isFalse);
    expect(model.visibleEvents, isNotEmpty);
  });

  test('фільтр за категорією', () {
    model.setDateFilter(EventDateFilter.all);
    model.setCategory(EventCategory.animals);
    expect(
      model.visibleEvents.every((e) => e.category == EventCategory.animals),
      isTrue,
    );
  });

  test('створення заходу додає його до списку', () async {
    model.setDateFilter(EventDateFilter.all);
    final before = model.visibleEvents.length;
    final ok = await model.createEvent(
      title: 'Тестовий захід',
      description: 'Опис',
      category: EventCategory.education,
      dateTime: DateTime.now().add(const Duration(days: 3)),
      location: 'Львів',
      participantLimit: 5,
    );
    expect(ok, isTrue);
    expect(model.visibleEvents.length, before + 1);
  });
}
