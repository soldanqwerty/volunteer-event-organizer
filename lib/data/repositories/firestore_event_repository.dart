import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_task.dart';
import '../models/participant.dart';
import '../models/volunteer_event.dart';
import 'event_repository.dart';

/// Реалізація [EventRepository] на Cloud Firestore (лаб. №6).
///
/// Структура бази:
/// ```
/// events/{eventId}                      — захід
/// events/{eventId}/participants/{uid}   — заявка учасника
/// events/{eventId}/tasks/{taskId}       — завдання заходу
/// users/{uid}                           — профіль (UserRepository)
/// ```
/// Учасники й завдання всіх заходів читаються одним запитом через
/// collectionGroup — так екрани «Заходи», «Головна» і «Мої завдання»
/// отримують лічильники та списки без запиту на кожен захід.
class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  CollectionReference<Map<String, dynamic>> _participantsOf(String eventId) =>
      _events.doc(eventId).collection('participants');

  CollectionReference<Map<String, dynamic>> _tasksOf(String eventId) =>
      _events.doc(eventId).collection('tasks');

  // ---------------------------------------------------------------- Заходи

  @override
  Future<List<VolunteerEvent>> fetchEvents() async {
    final snapshot = await _events.orderBy('startAt').get();
    return snapshot.docs.map(VolunteerEvent.fromFirestore).toList();
  }

  @override
  Future<VolunteerEvent> createEvent(VolunteerEvent draft) async {
    final ref = await _events.add({
      ...draft.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final created = await ref.get();
    return VolunteerEvent.fromFirestore(created);
  }

  @override
  Future<VolunteerEvent> updateEvent(VolunteerEvent event) async {
    await _events.doc(event.id).update({
      ...event.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return event;
  }

  /// FR-11. Firestore не видаляє підколекції автоматично, тому учасники
  /// й завдання видаляються в одному пакеті (WriteBatch) разом із заходом.
  @override
  Future<void> deleteEvent(String eventId) async {
    final participants = await _participantsOf(eventId).get();
    final tasks = await _tasksOf(eventId).get();

    final batch = _db.batch();
    for (final doc in [...participants.docs, ...tasks.docs]) {
      batch.delete(doc.reference);
    }
    batch.delete(_events.doc(eventId));
    await batch.commit();
  }

  // ------------------------------------------------------------- Учасники

  @override
  Future<List<Participant>> fetchParticipants() async {
    final snapshot = await _db.collectionGroup('participants').get();
    return snapshot.docs.map(Participant.fromFirestore).toList();
  }

  /// FR-12. Ім'я документа — uid, тож повторний запис неможливий.
  @override
  Future<Participant> addParticipant(Participant participant) async {
    final ref = _participantsOf(participant.eventId).doc(participant.userId);
    await ref.set(participant.toFirestore());
    return Participant.fromFirestore(await ref.get());
  }

  @override
  Future<Participant> updateParticipant(Participant participant) async {
    await _participantsOf(participant.eventId)
        .doc(participant.userId)
        .update({'status': participant.status.name});
    return participant;
  }

  /// FR-13. Видалення учасника знімає з нього призначені завдання заходу.
  @override
  Future<void> removeParticipant(Participant participant) async {
    final assigned = await _tasksOf(participant.eventId)
        .where('assigneeId', isEqualTo: participant.userId)
        .get();

    final batch = _db.batch();
    for (final doc in assigned.docs) {
      batch.update(doc.reference, {'assigneeId': null, 'assigneeName': null});
    }
    batch.delete(
      _participantsOf(participant.eventId).doc(participant.userId),
    );
    await batch.commit();
  }

  // ------------------------------------------------------------- Завдання

  @override
  Future<List<EventTask>> fetchTasks() async {
    final snapshot = await _db.collectionGroup('tasks').get();
    return snapshot.docs.map(EventTask.fromFirestore).toList();
  }

  @override
  Future<EventTask> createTask(EventTask draft) async {
    final ref = await _tasksOf(draft.eventId).add({
      ...draft.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return EventTask.fromFirestore(await ref.get());
  }

  @override
  Future<EventTask> updateTask(EventTask task) async {
    await _tasksOf(task.eventId).doc(task.id).update(task.toFirestore());
    return task;
  }

  @override
  Future<void> deleteTask(EventTask task) async {
    await _tasksOf(task.eventId).doc(task.id).delete();
  }
}
