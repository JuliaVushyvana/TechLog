import 'dart:math';

import '../utils.dart';
import 'models.dart';
import 'trainers.dart';

class AiUnavailable implements Exception {
  const AiUnavailable();
  @override
  String toString() =>
      'AI ще не підключено. Після налаштування Firebase фідбек писатиме Gemini. '
      'Поки що натисніть «Скопіювати запит» і вставте його в чат з AI.';
}

/// Генератор тексту фідбеку. Після `flutterfire configure` тут з'явиться
/// реалізація на Gemini через Firebase AI Logic (пакет firebase_ai) —
/// ключ API тоді не зберігається в коді застосунку.
abstract class FeedbackAi {
  bool get available;
  Future<String> generate({required String system, required String prompt});
}

class UnconfiguredAi implements FeedbackAi {
  const UnconfiguredAi();
  @override
  bool get available => false;
  @override
  Future<String> generate({required String system, required String prompt}) async => throw const AiUnavailable();
}

/// Дані для фідбеку за місяць.
class FeedbackData {
  FeedbackData(this.student, this.month, this.lessons, this.results);
  final Student student;

  /// yyyy-MM
  final String month;
  final List<Lesson> lessons;
  final List<TrainerResult> results;

  List<Lesson> get done => lessons.where((l) => l.status.counts).toList();

  /// Замало даних: менше двох проведених занять з описом або темою.
  bool get tooLittle => done.where((l) => l.description.isNotEmpty || l.topic.isNotEmpty).length < 2;

  String get monthLabel {
    final p = month.split('-');
    return '${months[int.parse(p[1]) - 1]} ${p[0]}';
  }
}

/// Прибирає прізвище з тексту: у модель іде лише ім'я учня.
String _anonymize(String text, Student s) {
  var out = text;
  for (final part in s.name.trim().split(RegExp(r'\s+')).skip(1)) {
    if (part.length > 1) out = out.replaceAll(part, '');
  }
  return out.replaceAll(RegExp(r' {2,}'), ' ').trim();
}

String buildSystemPrompt(AiSettings a) {
  final en = a.language == 'English';
  return '''
Ти помічник викладача дитячої школи (програмування, Roblox, ментальна арифметика). Пишеш щомісячні відгуки для батьків ${en ? 'англійською мовою' : 'українською мовою'}.
Правила:
- Спирайся лише на нотатки й дані викладача. Не вигадуй тем, оцінок чи подій, яких там немає. Якщо нотаток мало, пиши загальніше, але чесно.
- Звертайся до батьків на «ви», учня називай лише на ім’я.
- Структура: привітання; що вивчали цього місяця; що вдається добре; над чим варто попрацювати (м’яко й конструктивно); цифри прогресу на тренажерах, якщо вони є; 1–2 поради для занять удома; тепле завершення.
- Тон: ${AiSettings.tones[a.tone] ?? a.tone}. Обсяг: ${AiSettings.lengths[a.length] ?? a.length}.
- Простий текст без Markdown, заголовків і зірочок; абзаци розділяй порожнім рядком.
${a.signature.isNotEmpty ? '- Підпис наприкінці: ${a.signature}\n' : ''}${a.extra.isNotEmpty ? '- Додаткові побажання викладача: ${a.extra}\n' : ''}Відповідай лише текстом відгуку.'''
      .trim();
}

String buildUserPrompt(FeedbackData d) {
  final s = d.student;
  final b = StringBuffer()
    ..writeln('Учень: ${s.firstName}${s.age != null ? ', ${s.age} р.' : ''}')
    ..writeln('Напрям: ${s.directions.join(', ')}');
  if (s.level.isNotEmpty) b.writeln('Поточний рівень: ${s.level}');
  if (s.inclusion) {
    b.writeln(
      'Особливі освітні потреби: так (пиши особливо делікатно, відзначай навіть невеликий прогрес, '
      'не згадуй діагнози і слово «інклюзія»).',
    );
  }
  if (s.notes.isNotEmpty) b.writeln('Нотатки викладача про учня: ${_anonymize(s.notes, s)}');
  b
    ..writeln('Місяць: ${d.monthLabel}')
    ..writeln(
      'Проведено занять: ${d.done.length}, '
      'скасовано: ${d.lessons.where((l) => l.status == LessonStatus.cancelled).length}',
    )
    ..writeln()
    ..writeln('Заняття за місяць:');
  if (d.lessons.isEmpty) b.writeln('(занять немає)');
  for (final l in d.lessons) {
    b.writeln(
      [
        '- ${fd(l.date)}',
        l.type,
        l.status.label,
        if (l.topic.isNotEmpty) 'тема: ${_anonymize(l.topic, s)}',
        if (l.description.isNotEmpty) 'опис: ${_anonymize(l.description, s)}',
        if (l.activity != null) 'активність ${l.activity}/5',
      ].join(' · '),
    );
  }

  final groups = <String, List<TrainerResult>>{};
  for (final r in d.results) {
    final t = trainerBy(r.trainer);
    groups.putIfAbsent('${t.name} (${t.settingsLabel(r.settings)})', () => []).add(r);
  }
  if (groups.isNotEmpty) {
    b
      ..writeln()
      ..writeln('Результати на тренажерах (початок і кінець місяця):');
    for (final e in groups.entries) {
      final a = e.value;
      final best = a.map((r) => r.timeSec).reduce(min);
      final change = a.length > 1 ? ((a.first.timeSec - a.last.timeSec) / a.first.timeSec * 100).round() : null;
      final correct = a.last.correct == null
          ? ''
          : ', правильно в останній спробі ${a.last.correct}/${a.last.total ?? '?'}';
      b.writeln(
        '- ${e.key}: спроб ${a.length}, перший час ${fmtSec(a.first.timeSec)} с, '
        'останній ${fmtSec(a.last.timeSec)} с, найкращий ${fmtSec(best)} с'
        '${change == null ? '' : ', зміна ${change >= 0 ? 'швидше' : 'повільніше'} на ${change.abs()}%'}$correct',
      );
    }
  }
  b
    ..writeln()
    ..write('Напиши щомісячний фідбек батькам цього учня.');
  return b.toString();
}
