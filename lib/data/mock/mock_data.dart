import '../models/event_task.dart';
import '../models/participant.dart';
import '../models/volunteer_event.dart';

/// Захардкоджені початкові дані (дозволено завданням лаб. №5).
///
/// Дати рахуються відносно поточного дня, тому фільтри «Найближчі» та
/// «Минулі» завжди мають що показати. Частину заходів організовує поточний
/// користувач — так можна перевірити редагування і видалення.
class MockData {
  MockData._();

  static DateTime _day(int offset, int hour, [int minute = 0]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset, hour, minute);
  }

  static List<VolunteerEvent> events({
    required String currentUserId,
    required String currentUserName,
  }) {
    return [
      VolunteerEvent(
        id: 'e1',
        title: 'Чистий парк разом',
        description:
            'Прибирання Стрийського парку: збір сміття, фарбування лавок '
            'і висадка квітів. Рукавички та мішки видаємо на місці.',
        category: EventCategory.ecology,
        dateTime: _day(2, 10),
        endDateTime: _day(2, 13),
        location: 'Стрийський парк, Львів',
        participantLimit: 20,
        organizerId: currentUserId,
        organizerName: currentUserName,
      ),
      VolunteerEvent(
        id: 'e2',
        title: 'Продукти для родин',
        description:
            'Пакування та роздача продуктових наборів для родин '
            'внутрішньо переміщених осіб.',
        category: EventCategory.social,
        dateTime: _day(5, 12, 30),
        endDateTime: _day(5, 15, 30),
        location: 'Волонтерський центр, вул. Городоцька, 15',
        participantLimit: 12,
        organizerId: 'u-olena',
        organizerName: 'Олена Коваль',
      ),
      VolunteerEvent(
        id: 'e3',
        title: 'День турботи про тварин',
        description:
            'Вигул собак, прибирання вольєрів і фотосесія тварин '
            'для оголошень про прилаштування.',
        category: EventCategory.animals,
        dateTime: _day(9, 11),
        endDateTime: _day(9, 14),
        location: 'Притулок «Сіріус»',
        participantLimit: 15,
        organizerId: 'u-taras',
        organizerName: 'Тарас Мельник',
      ),
      VolunteerEvent(
        id: 'e4',
        title: 'Уроки англійської для дітей',
        description:
            'Безкоштовні заняття англійською для дітей 8–12 років. '
            'Потрібні волонтери з рівнем B1+.',
        category: EventCategory.education,
        dateTime: _day(14, 16),
        endDateTime: _day(14, 19),
        location: 'Бібліотека-філія №5',
        participantLimit: 6,
        organizerId: currentUserId,
        organizerName: currentUserName,
      ),
      VolunteerEvent(
        id: 'e5',
        title: 'Висадка дерев на Високому замку',
        description: 'Осіння висадка 200 саджанців клена та липи.',
        category: EventCategory.ecology,
        dateTime: _day(-6, 9),
        endDateTime: _day(-6, 12),
        location: 'Парк «Високий замок»',
        participantLimit: 30,
        organizerId: 'u-olena',
        organizerName: 'Олена Коваль',
      ),
      VolunteerEvent(
        id: 'e6',
        title: 'Збір одягу для переселенців',
        description: 'Сортування та пакування теплого одягу перед зимою.',
        category: EventCategory.social,
        dateTime: _day(21, 10),
        endDateTime: _day(21, 13),
        location: 'Пункт збору, пл. Ринок, 1',
        participantLimit: 10,
        organizerId: 'u-taras',
        organizerName: 'Тарас Мельник',
      ),
    ];
  }

  static List<Participant> participants({
    required String currentUserId,
    required String currentUserName,
    required String currentUserEmail,
  }) {
    return [
      const Participant(
        id: 'p1',
        eventId: 'e1',
        userId: 'u-olena',
        name: 'Олена Коваль',
        email: 'o.koval@example.com',
        status: ParticipantStatus.confirmed,
      ),
      const Participant(
        id: 'p2',
        eventId: 'e1',
        userId: 'u-taras',
        name: 'Тарас Мельник',
        email: 't.melnyk@example.com',
        status: ParticipantStatus.confirmed,
      ),
      const Participant(
        id: 'p3',
        eventId: 'e1',
        userId: 'u-maria',
        name: 'Марія Шевчук',
        email: 'm.shevchuk@example.com',
        status: ParticipantStatus.pending,
      ),
      const Participant(
        id: 'p4',
        eventId: 'e1',
        userId: 'u-andrii',
        name: 'Андрій Бойко',
        email: 'a.boiko@example.com',
        status: ParticipantStatus.rejected,
      ),
      Participant(
        id: 'p5',
        eventId: 'e2',
        userId: currentUserId,
        name: currentUserName,
        email: currentUserEmail,
        status: ParticipantStatus.confirmed,
      ),
      const Participant(
        id: 'p6',
        eventId: 'e2',
        userId: 'u-maria',
        name: 'Марія Шевчук',
        email: 'm.shevchuk@example.com',
        status: ParticipantStatus.confirmed,
      ),
      Participant(
        id: 'p7',
        eventId: 'e3',
        userId: currentUserId,
        name: currentUserName,
        email: currentUserEmail,
        status: ParticipantStatus.pending,
      ),
      const Participant(
        id: 'p8',
        eventId: 'e4',
        userId: 'u-sofia',
        name: 'Софія Лисенко',
        email: 's.lysenko@example.com',
        status: ParticipantStatus.pending,
      ),
    ];
  }

  static List<EventTask> tasks({
    required String currentUserId,
    required String currentUserName,
  }) {
    return [
      EventTask(
        id: 't1',
        eventId: 'e1',
        title: 'Підтвердити список учасників',
        description: 'Переглянути заявки та підтвердити учасників.',
        dueDate: _day(0, 18),
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        assigneeId: currentUserId,
        assigneeName: currentUserName,
      ),
      EventTask(
        id: 't2',
        eventId: 'e1',
        title: 'Зібрати інвентар для прибирання',
        description: 'Рукавички, мішки, граблі — на 20 осіб.',
        dueDate: _day(1, 12),
        priority: TaskPriority.medium,
        status: TaskStatus.newTask,
        assigneeId: 'u-taras',
        assigneeName: 'Тарас Мельник',
      ),
      EventTask(
        id: 't3',
        eventId: 'e2',
        title: 'Зателефонувати постачальнику продуктів',
        description: 'Узгодити час доставки наборів.',
        dueDate: _day(3, 10),
        priority: TaskPriority.low,
        status: TaskStatus.newTask,
        assigneeId: currentUserId,
        assigneeName: currentUserName,
      ),
      EventTask(
        id: 't4',
        eventId: 'e2',
        title: 'Підготувати списки родин',
        description: 'Звірити списки з базою центру.',
        dueDate: _day(4, 15),
        priority: TaskPriority.high,
        status: TaskStatus.done,
        assigneeId: currentUserId,
        assigneeName: currentUserName,
      ),
      EventTask(
        id: 't5',
        eventId: 'e1',
        title: 'Купити саджанці квітів',
        description: 'Бюджет — 1500 грн.',
        dueDate: _day(1, 17),
        priority: TaskPriority.medium,
        status: TaskStatus.newTask,
      ),
      EventTask(
        id: 't6',
        eventId: 'e4',
        title: 'Підготувати навчальні матеріали',
        description: 'Роздруківки та картки зі словами.',
        dueDate: _day(12, 12),
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        assigneeId: currentUserId,
        assigneeName: currentUserName,
      ),
    ];
  }
}
