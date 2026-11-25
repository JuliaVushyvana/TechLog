import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachlog/data/models.dart';
import 'package:teachlog/data/repository.dart';
import 'package:teachlog/data/store.dart';

void main() {
  late LocalDataRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = LocalDataRepository(await SharedPreferences.getInstance());
  });

  test('учні зберігаються і відновлюються після перезапуску', () async {
    final store = AppStore(repo, 't1')
      ..addStudent(Student(id: 's1', name: 'Ілля Коваль', age: 9, directions: ['Roblox', 'МА']));
    await Future<void>.delayed(Duration.zero);

    final again = AppStore(repo, 't1');
    await again.load();
    expect(again.students.single.name, 'Ілля Коваль');
    expect(again.students.single.directions, ['Roblox', 'МА']);
    expect(store.activeStudents, hasLength(1));
  });

  test('архівний учень зникає з активних, але лишається в даних', () {
    final store = AppStore(repo, 't1')..addStudent(Student(id: 's1', name: 'Аня'));
    store.setArchived(store.students.single, true);
    expect(store.activeStudents, isEmpty);
    expect(store.students, hasLength(1));
  });

  test('видалення учня прибирає його заняття й результати', () {
    final store = AppStore(repo, 't1')
      ..addStudent(Student(id: 's1', name: 'Аня'))
      ..addStudent(Student(id: 's2', name: 'Борис'));
    store.lessons
      ..add(Lesson(id: 'l1', date: '2026-11-02', time: '16:00', studentId: 's1', type: 'IT 45 день'))
      ..add(Lesson(id: 'l2', date: '2026-11-02', time: '17:00', studentId: 's2', type: 'IT 45 день'));
    store.results.add(
      TrainerResult(
        id: 'r1',
        studentId: 's1',
        trainer: 'pair',
        settings: {'cards': '8'},
        date: '2026-11-02',
        timeSec: 30,
      ),
    );

    store.deleteStudent('s1');
    expect(store.students.map((s) => s.id), ['s2']);
    expect(store.lessons.map((l) => l.id), ['l2']);
    expect(store.results, isEmpty);
  });

  test('дані різних вчителів не змішуються', () async {
    AppStore(repo, 't1').addStudent(Student(id: 's1', name: 'Аня'));
    await Future<void>.delayed(Duration.zero);
    final other = AppStore(repo, 't2');
    await other.load();
    expect(other.students, isEmpty);
  });

  test('учні без занять понад 2 тижні', () {
    final store = AppStore(repo, 't1')
      ..addStudent(Student(id: 's1', name: 'Аня'))
      ..addStudent(Student(id: 's2', name: 'Борис'))
      ..addStudent(Student(id: 's3', name: 'Віка'));
    final now = DateTime.now();
    String daysAgo(int n) {
      final d = DateTime(now.year, now.month, now.day - n);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    store.addLessons([
      Lesson(id: 'a', date: daysAgo(3), time: '16:00', studentId: 's1', type: 'IT', status: LessonStatus.done),
      Lesson(id: 'b', date: daysAgo(20), time: '16:00', studentId: 's2', type: 'IT', status: LessonStatus.done),
      Lesson(id: 'c', date: daysAgo(2), time: '16:00', studentId: 's2', type: 'IT', status: LessonStatus.cancelled),
    ]);
    final idle = store.idleStudents();
    expect(idle.map((e) => e.$1.id), ['s2', 's3']);
    expect(idle.first.$2, daysAgo(20));
    expect(idle.last.$2, isNull);
  });
}
