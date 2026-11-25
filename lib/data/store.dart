import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../utils.dart';
import 'feedback_ai.dart';
import 'models.dart';
import 'repository.dart';
import 'trainers.dart';

/// Усі дані вчителя в пам'яті. Кожна зміна зберігається в [DataRepository].
class AppStore extends ChangeNotifier {
  AppStore(this._repo, this.teacherId);

  final DataRepository _repo;
  final String? teacherId;

  bool loaded = false;
  List<Student> students = [];
  List<Lesson> lessons = [];
  List<Schedule> schedules = [];
  List<TrainerResult> results = [];
  Map<String, FeedbackDoc> feedbacks = {};

  Future<void>? _loading;

  /// Завантажує дані один раз; повторні виклики чекають на те саме завантаження.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final id = teacherId;
    if (id != null) {
      final j = await _repo.load(id);
      List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => [
        for (final e in (j[k] as List? ?? const [])) f((e as Map).cast<String, dynamic>()),
      ];
      students = list('students', Student.fromJson);
      lessons = list('lessons', Lesson.fromJson);
      schedules = list('schedules', Schedule.fromJson);
      results = list('trainerResults', TrainerResult.fromJson);
      feedbacks = {for (final f in list('feedbacks', FeedbackDoc.fromJson)) f.key: f};
      skips = {...?(j['skips'] as List?)?.cast<String>()};
    }
    loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'students': [for (final s in students) s.toJson()],
    'lessons': [for (final l in lessons) l.toJson()],
    'schedules': [for (final s in schedules) s.toJson()],
    'trainerResults': [for (final r in results) r.toJson()],
    'feedbacks': [for (final f in feedbacks.values) f.toJson()],
    'skips': skips.toList(),
  };

  /// Сповіщає UI і зберігає дані.
  void changed() {
    notifyListeners();
    final id = teacherId;
    if (id != null) _repo.save(id, toJson());
  }

  // ---------- Учні ----------

  Student? student(String id) => students.where((s) => s.id == id).firstOrNull;

  /// Учні для списків вибору: без архівних, за алфавітом.
  List<Student> get activeStudents =>
      students.where((s) => !s.archived).toList()..sort((a, b) => a.name.compareTo(b.name));

  void addStudent(Student s) {
    students.add(s);
    changed();
  }

  void setArchived(Student s, bool archived) {
    s.archived = archived;
    changed();
  }

  /// Видаляє учня разом з його заняттями, розкладом, результатами й фідбеками.
  void deleteStudent(String id) {
    students.removeWhere((s) => s.id == id);
    lessons.removeWhere((l) => l.studentId == id);
    schedules.removeWhere((s) => s.studentId == id);
    results.removeWhere((r) => r.studentId == id);
    feedbacks.removeWhere((_, f) => f.studentId == id);
    changed();
  }

  // ---------- Заняття ----------

  Lesson? lesson(String id) => lessons.where((l) => l.id == id).firstOrNull;

  List<Lesson> lessonsOn(String date) =>
      lessons.where((l) => l.date == date).toList()..sort((a, b) => a.time.compareTo(b.time));

  /// Попередні теми для автопідказки, найсвіжіші першими.
  List<String> get topics {
    final sorted = [...lessons]..sort((a, b) => b.date.compareTo(a.date));
    return {
      for (final l in sorted)
        if (l.topic.isNotEmpty) l.topic,
    }.toList();
  }

  void addLessons(Iterable<Lesson> ls) {
    lessons.addAll(ls);
    changed();
  }

  /// Видаляє одне заняття. Якщо воно з постійного розкладу, цю дату запам'ятовуємо,
  /// щоб розклад не створив заняття знову.
  void deleteLesson(String id) {
    final l = lesson(id);
    if (l == null) return;
    if (l.scheduleId != null) skips.add('${l.scheduleId}|${l.origDate ?? l.date}');
    lessons.remove(l);
    changed();
  }

  /// Перемикач статусу: повторне натискання повертає «заплановано».
  void toggleStatus(Lesson l, LessonStatus s) {
    l.status = l.status == s ? LessonStatus.planned : s;
    changed();
  }

  // ---------- Постійний розклад ----------

  /// Дати, на які заняття з розкладу видалили вручну: '{scheduleId}|{yyyy-MM-dd}'.
  Set<String> skips = {};

  void addSchedule(Schedule s) {
    schedules.add(s);
    changed();
  }

  void updateSchedule(Schedule s) {
    _resetSchedule(s.id);
    changed();
  }

  void deleteSchedule(String id) {
    schedules.removeWhere((s) => s.id == id);
    _resetSchedule(id);
    changed();
  }

  /// Прибирає майбутні незаповнені заняття розкладу — їх буде створено заново.
  /// Проведені й заповнені заняття лишаються.
  void _resetSchedule(String id) {
    final t = iso(today());
    lessons.removeWhere(
      (l) => l.scheduleId == id && l.date.compareTo(t) >= 0 && l.status == LessonStatus.planned && l.isBlank,
    );
    skips.removeWhere((k) => k.startsWith('$id|'));
  }

  /// Створює заняття постійного розкладу на місяць [month], яких ще немає.
  void generateMonth(DateTime month) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final added = <Lesson>[];
    for (var day = 1; day <= days; day++) {
      final d = DateTime(month.year, month.month, day);
      final k = iso(d);
      for (final s in schedules) {
        if (s.weekday != wd(d) || k.compareTo(s.from) < 0 || skips.contains('${s.id}|$k')) continue;
        final st = student(s.studentId);
        if (st == null || st.archived) continue;
        if (lessons.any((l) => l.scheduleId == s.id && (l.date == k || l.origDate == k))) continue;
        added.add(
          Lesson(
            id: newId(),
            date: k,
            time: s.time,
            studentId: s.studentId,
            type: s.type,
            scheduleId: s.id,
            origDate: k,
          ),
        );
      }
    }
    if (added.isNotEmpty) addLessons(added);
  }

  // ---------- Тренажери ----------

  /// Спроби учня на тренажері з однаковими налаштуваннями, у порядку запису.
  /// Час на різних налаштуваннях непорівнянний, тому прогрес рахується лише тут.
  List<TrainerResult> attempts(String studentId, String settingsKey) => results
      .where((r) => r.studentId == studentId && trainerBy(r.trainer).settingsKey(r.settings) == settingsKey)
      .toList();

  double? best(String studentId, String settingsKey) {
    final a = attempts(studentId, settingsKey);
    return a.isEmpty ? null : a.map((r) => r.timeSec).reduce(min);
  }

  /// Зберігає результат. Повертає true, якщо це новий особистий рекорд
  /// (кращий за попередні спроби з тими самими налаштуваннями).
  bool addResult(TrainerResult r) {
    final prev = best(r.studentId, trainerBy(r.trainer).settingsKey(r.settings));
    results.add(r);
    changed();
    return prev != null && r.timeSec < prev;
  }

  void deleteResult(String id) {
    results.removeWhere((r) => r.id == id);
    changed();
  }

  /// Налаштування останньої спроби учня на цьому тренажері («Як минулого разу»).
  Map<String, String>? lastSettings(String studentId, String trainer) =>
      results.lastWhereOrNull((r) => r.studentId == studentId && r.trainer == trainer)?.settings;

  // ---------- Фідбеки ----------

  FeedbackDoc? feedback(String studentId, String month) => feedbacks['$studentId|$month'];

  /// Зберігає текст фідбеку; порожній текст видаляє фідбек.
  void setFeedback(String studentId, String month, String text) {
    final key = '$studentId|$month';
    if (text.trim().isEmpty) {
      feedbacks.remove(key);
    } else {
      feedbacks[key] = FeedbackDoc(studentId: studentId, month: month, text: text, updated: iso(today()));
    }
    changed();
  }

  /// Учні, які мали проведені заняття в місяці [month] (yyyy-MM).
  List<Student> studentsWithLessons(String month) {
    final ids = {
      for (final l in lessons)
        if (l.date.startsWith(month) && l.status.counts) l.studentId,
    };
    return students.where((s) => ids.contains(s.id)).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  FeedbackData feedbackData(Student s, String month) => FeedbackData(
    s,
    month,
    lessons.where((l) => l.studentId == s.id && l.date.startsWith(month)).toList()
      ..sort((a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}')),
    results.where((r) => r.studentId == s.id && r.date.startsWith(month)).toList(),
  );

  // ---------- Статистика ----------

  List<Lesson> lessonsInMonth(String month) => lessons.where((l) => l.date.startsWith(month)).toList();

  /// Активні учні, у яких не було проведених занять понад [days] днів
  /// (разом з датою останнього; null — занять не було взагалі).
  List<(Student, String?)> idleStudents({int days = 14}) {
    final border = iso(today().subtract(Duration(days: days)));
    final out = <(Student, String?)>[];
    for (final s in activeStudents) {
      final done = lessons.where((l) => l.studentId == s.id && l.status.counts).map((l) => l.date);
      final last = done.isEmpty ? null : done.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      if (last == null || last.compareTo(border) < 0) out.add((s, last));
    }
    return out;
  }

  // ---------- Вибірки для картки учня ----------

  List<Lesson> lessonsOf(String studentId) =>
      lessons.where((l) => l.studentId == studentId).toList()
        ..sort((a, b) => '${b.date}${b.time}'.compareTo('${a.date}${a.time}'));

  List<TrainerResult> resultsOf(String studentId) =>
      results.where((r) => r.studentId == studentId).toList()..sort((a, b) => b.date.compareTo(a.date));

  List<FeedbackDoc> feedbacksOf(String studentId) =>
      feedbacks.values.where((f) => f.studentId == studentId).toList()..sort((a, b) => b.month.compareTo(a.month));

  /// Скільки проведених занять у учня в поточному місяці.
  int doneThisMonth(String studentId) {
    final m = ym(today());
    return lessons.where((l) => l.studentId == studentId && l.date.startsWith(m) && l.status.counts).length;
  }
}
