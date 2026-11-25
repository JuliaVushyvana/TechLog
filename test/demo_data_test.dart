import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachlog/data/demo_data.dart';
import 'package:teachlog/data/models.dart';
import 'package:teachlog/providers.dart';
import 'package:teachlog/ui/feedback/feedback_screen.dart';
import 'package:teachlog/ui/home/home_screen.dart';
import 'package:teachlog/ui/schedule/schedule_screen.dart';
import 'package:teachlog/ui/theme.dart';
import 'package:teachlog/ui/trainers/trainers_screen.dart';
import 'package:teachlog/utils.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(await SharedPreferences.getInstance())]);
    addTearDown(c.dispose);
    await c.read(storeProvider).load();
    return c;
  }

  test('тестові дані: учні, розклад, заняття, тренажери, фідбек', () async {
    final store = (await container()).read(storeProvider);
    seedDemoData(store);
    final t = iso(today());

    expect(store.students, hasLength(10));
    expect(store.activeStudents, hasLength(9));
    expect(store.schedules, isNotEmpty);
    expect(store.lessons.where((l) => l.date.compareTo(t) < 0 && l.status == LessonStatus.done), isNotEmpty);
    expect(store.lessons.where((l) => l.date.compareTo(t) > 0 && l.status == LessonStatus.planned), isNotEmpty);
    expect(store.lessons.where((l) => l.date.compareTo(t) >= 0 && l.status != LessonStatus.planned), isEmpty);
    // Архівний учень без занять.
    final roman = store.students.firstWhere((s) => s.archived);
    expect(store.lessonsOf(roman.id), isEmpty);
    // Остап давно не був.
    expect(store.idleStudents().map((e) => e.$1.name), contains('Остап Гнатюк'));
    // Результати лише в учнів МА, час з часом кращає.
    final martin = store.students.firstWhere((s) => s.name.startsWith('Мартін'));
    final flash = store.results.where((r) => r.studentId == martin.id && r.trainer == 'flash').toList();
    expect(flash.length, greaterThan(3));
    expect(flash.last.timeSec, lessThan(flash.first.timeSec));
    expect(store.results.every((r) => store.student(r.studentId)!.directions.contains('МА')), isTrue);
    expect(store.feedbacks, hasLength(1));
  });

  for (final (name, screen) in [
    ('Головна', const HomeScreen()),
    ('Розклад', const ScheduleScreen()),
    ('Тренажери', const TrainersScreen()),
    ('Фідбеки', const FeedbackScreen()),
  ]) {
    testWidgets('$name з тестовими даними без переповнень', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await container();
      seedDemoData(c.read(storeProvider));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(body: screen),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
