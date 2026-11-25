import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachlog/data/models.dart';
import 'package:teachlog/data/repository.dart';
import 'package:teachlog/data/store.dart';
import 'package:teachlog/data/trainers.dart';

void main() {
  late AppStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(LocalDataRepository(await SharedPreferences.getInstance()), 't1')
      ..addStudent(Student(id: 's1', name: 'Мартін', directions: ['МА']));
  });

  final shulte = trainerBy('shulte');
  Map<String, String> field(String f) => {...shulte.defaults(), 'field': f};

  TrainerResult res(Map<String, String> s, double t) =>
      TrainerResult(id: newId(), studentId: 's1', trainer: 'shulte', settings: s, date: '2026-11-02', timeSec: t);

  test('перша спроба не є рекордом, краща за попередні — є', () {
    expect(store.addResult(res(field('3×3'), 30)), isFalse);
    expect(store.addResult(res(field('3×3'), 32)), isFalse);
    expect(store.addResult(res(field('3×3'), 25.5)), isTrue);
    expect(store.best('s1', shulte.settingsKey(field('3×3'))), 25.5);
  });

  test('різні налаштування — різні лінії й рекорди', () {
    store.addResult(res(field('3×3'), 20));
    expect(store.addResult(res(field('5×5'), 60)), isFalse);
    expect(store.attempts('s1', shulte.settingsKey(field('3×3'))), hasLength(1));
    expect(store.attempts('s1', shulte.settingsKey(field('5×5'))), hasLength(1));
  });

  test('«Як минулого разу» бере останні налаштування на цьому тренажері', () {
    store.addResult(res(field('3×3'), 20));
    store.addResult(res(field('6×6'), 80));
    expect(store.lastSettings('s1', 'shulte')!['field'], '6×6');
    expect(store.lastSettings('s1', 'flash'), isNull);
  });
}
