import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachlog/data/models.dart';
import 'package:teachlog/data/repository.dart';
import 'package:teachlog/data/store.dart';

void main() {
  late AppStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(LocalDataRepository(await SharedPreferences.getInstance()), 't1')
      ..addStudent(Student(id: 's1', name: 'Ілля'));
  });

  // Листопад 2026: понеділки 2, 9, 16, 23, 30.
  final nov = DateTime(2026, 11);

  Schedule mondays({String from = '2026-11-01'}) =>
      Schedule(id: 'p1', weekday: 0, time: '16:00', studentId: 's1', type: 'IT 45 день', from: from);

  test('розклад створює заняття на кожен понеділок місяця, без дублів', () {
    store.addSchedule(mondays());
    store.generateMonth(nov);
    store.generateMonth(nov);
    expect(store.lessons.map((l) => l.date), ['2026-11-02', '2026-11-09', '2026-11-16', '2026-11-23', '2026-11-30']);
  });

  test('«діє з» обмежує початок', () {
    store.addSchedule(mondays(from: '2026-11-15'));
    store.generateMonth(nov);
    expect(store.lessons.map((l) => l.date), ['2026-11-16', '2026-11-23', '2026-11-30']);
  });

  test('видалене вручну заняття розклад не відновлює', () {
    store.addSchedule(mondays());
    store.generateMonth(nov);
    store.deleteLesson(store.lessonsOn('2026-11-09').single.id);
    store.generateMonth(nov);
    expect(store.lessonsOn('2026-11-09'), isEmpty);
    expect(store.lessons, hasLength(4));
  });

  test('перенесене заняття не дублюється на старій даті', () {
    store.addSchedule(mondays());
    store.generateMonth(nov);
    store.lessonsOn('2026-11-09').single.date = '2026-11-10';
    store.generateMonth(nov);
    expect(store.lessonsOn('2026-11-09'), isEmpty);
    expect(store.lessonsOn('2026-11-10'), hasLength(1));
  });

  test('архівний учень не отримує нових занять', () {
    store.addSchedule(mondays());
    store.setArchived(store.students.single, true);
    store.generateMonth(nov);
    expect(store.lessons, isEmpty);
  });

  test('статус перемикається і повертається в «заплановано»', () {
    store.addLessons([Lesson(id: 'l1', date: '2026-11-02', time: '16:00', studentId: 's1', type: 'IT 45 день')]);
    final l = store.lesson('l1')!;
    store.toggleStatus(l, LessonStatus.cancelled);
    expect(l.status, LessonStatus.cancelled);
    store.toggleStatus(l, LessonStatus.cancelled);
    expect(l.status, LessonStatus.planned);
  });
}
