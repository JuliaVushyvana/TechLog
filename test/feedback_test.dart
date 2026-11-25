import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachlog/data/feedback_ai.dart';
import 'package:teachlog/data/models.dart';
import 'package:teachlog/data/repository.dart';
import 'package:teachlog/data/store.dart';
import 'package:teachlog/providers.dart';
import 'package:teachlog/ui/feedback/feedback_screen.dart';
import 'package:teachlog/ui/theme.dart';
import 'package:teachlog/utils.dart';

class _FakeAi implements FeedbackAi {
  String? lastPrompt;
  @override
  bool get available => true;
  @override
  Future<String> generate({required String system, required String prompt}) async {
    lastPrompt = prompt;
    return 'Добрий день! Мартін чудово попрацював.';
  }
}

Student _martin() => Student(
  id: 's1',
  name: 'Мартін Фюзеш',
  age: 8,
  directions: ['МА'],
  parentContact: '+380501234567',
  notes: 'Фюзеш любить флешкарти',
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late AppStore store;
  final month = ym(today());
  String day(int d) => '$month-${pad2(d)}';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(LocalDataRepository(await SharedPreferences.getInstance()), 't1')..addStudent(_martin());
  });

  test('у запит іде лише ім’я: без прізвища й контакту батьків', () {
    store.addLessons([
      Lesson(
        id: 'a',
        date: day(2),
        time: '16:00',
        studentId: 's1',
        type: 'МА 45 день',
        status: LessonStatus.done,
        topic: 'Молодші друзі',
        description: 'Фюзеш рахує швидше',
        activity: 5,
      ),
    ]);
    final p = buildUserPrompt(store.feedbackData(store.student('s1')!, month));
    expect(p, contains('Учень: Мартін, 8 р.'));
    expect(p, contains('Молодші друзі'));
    expect(p, contains('активність 5/5'));
    expect(p, isNot(contains('Фюзеш')));
    expect(p, isNot(contains('380501234567')));
  });

  test('менше двох занять з описом — даних замало', () {
    store.addLessons([
      Lesson(id: 'a', date: day(2), time: '16:00', studentId: 's1', type: 'МА', status: LessonStatus.done, topic: 'x'),
      Lesson(id: 'b', date: day(3), time: '16:00', studentId: 's1', type: 'МА', status: LessonStatus.done),
    ]);
    expect(store.feedbackData(store.student('s1')!, month).tooLittle, isTrue);
    store.lesson('b')!.description = 'добре';
    expect(store.feedbackData(store.student('s1')!, month).tooLittle, isFalse);
  });

  test('порожній текст видаляє фідбек', () {
    store.setFeedback('s1', month, 'Текст');
    expect(store.feedbacksOf('s1'), hasLength(1));
    store.setFeedback('s1', month, '  ');
    expect(store.feedbacksOf('s1'), isEmpty);
  });

  testWidgets('кнопка «Згенерувати» пише фідбек в архів учня', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final prefs = await SharedPreferences.getInstance();
    final ai = _FakeAi();
    final c = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs), feedbackAiProvider.overrideWithValue(ai)],
    );
    addTearDown(c.dispose);
    final s = c.read(storeProvider);
    await s.load();
    s
      ..addStudent(_martin())
      ..addLessons([
        Lesson(id: 'a', date: day(2), time: '16:00', studentId: 's1', type: 'МА 45 день', status: LessonStatus.done),
      ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: FeedbackScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Даних замало'), findsOneWidget);

    await tester.tap(find.text('Згенерувати'));
    await tester.pump();
    await tester.pump();
    expect(s.feedback('s1', month)?.text, 'Добрий день! Мартін чудово попрацював.');
    expect(find.text('Перегенерувати'), findsOneWidget);
    expect(ai.lastPrompt, isNot(contains('Фюзеш')));
    expect(tester.takeException(), isNull);
  });
}
