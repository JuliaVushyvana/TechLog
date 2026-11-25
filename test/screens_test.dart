import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachlog/data/models.dart';
import 'package:teachlog/providers.dart';
import 'package:teachlog/ui/home/home_screen.dart';
import 'package:teachlog/ui/schedule/schedule_screen.dart';
import 'package:teachlog/ui/theme.dart';
import 'package:teachlog/ui/trainers/trainers_screen.dart';
import 'package:teachlog/utils.dart';

/// Рендерить екрани на вузькому телефоні (360×740), щоб зловити переповнення розмітки.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<ProviderContainer> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    final store = container.read(storeProvider);
    await store.load();
    final t = iso(today());
    store.addStudent(Student(id: 's1', name: 'Мартін Фюзеш', directions: ['МА']));
    store.addStudent(Student(id: 's2', name: 'Ілля Коваленко-Довгопрізвищний', directions: ['Roblox']));
    store.addLessons([
      for (var i = 0; i < 5; i++)
        Lesson(
          id: 'l$i',
          date: t,
          time: '1${i + 3}:00',
          studentId: i.isEven ? 's1' : 's2',
          type: 'IT 45 ПУ день',
          topic: 'Lua, сл. 23 — цикли та змінні, дуже довга тема заняття',
          status: LessonStatus.values[i % 4],
        ),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(body: screen),
        ),
      ),
    );
    // Таймер splash в LocalAuthService.init.
    await tester.pump(const Duration(seconds: 2));
    return container;
  }

  testWidgets('Головна без переповнень', (tester) async {
    await pump(tester, const HomeScreen());
    expect(find.text('проведено'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Розклад без переповнень', (tester) async {
    await pump(tester, const ScheduleScreen());
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump();
    expect(find.textContaining('занять: 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Тренажери з графіком без переповнень', (tester) async {
    final c = await pump(tester, const TrainersScreen());
    final store = c.read(storeProvider);
    for (final t in [40.0, 35.5, 37.0, 31.2]) {
      store.addResult(
        TrainerResult(
          id: newId(),
          studentId: 's1',
          trainer: 'flash',
          settings: {'axes': '1', 'nums': '4-4', 'dir': 'Число → Абакус', 'mode': 'Тренування', 'ans': '15'},
          date: iso(today()),
          timeSec: t,
          correct: 14,
          total: 15,
        ),
      );
    }
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump();
    expect(find.textContaining('швидше на 22%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
