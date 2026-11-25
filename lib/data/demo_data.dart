import 'dart:math';

import '../utils.dart';
import 'models.dart';
import 'store.dart';

const demoEmail = 'demo@teachlog.app';
const demoPassword = 'demo123';
const demoName = 'Олена Демченко';

const _topics = {
  'Roblox': [
    'Lua: змінні',
    'Lua: умови if',
    'Lua: цикли for',
    'Lua: функції',
    'Подія Touched',
    'GUI: кнопки й лічильник',
    'Obby: рухомі платформи',
    'DataStore: збереження',
  ],
  'Start & Click': [
    'Scratch: рух спрайта',
    'Scratch: цикли',
    'Scratch: змінні й рахунок',
    'Гра «Лабіринт»',
    'Анімація персонажа',
    'Керування клавіатурою',
  ],
  'МА': [
    'Прямий рахунок',
    'Молодші друзі +',
    'Молодші друзі −',
    'Старші друзі +',
    'Старші друзі −',
    'Комбінації',
    'Флешкарти, 1 вісь',
    'Ментальний рахунок, 2 дії',
  ],
};

const _descriptions = [
  'Тема далася легко, є запит на ускладнення',
  'Плутанина з порядком дій — повторили на прикладах',
  'Під кінець заняття втома, але завдання виконано',
  'З абакусом впевнено, ментально ще повільно',
  'Міні-проєкт виконано повністю самостійно',
  'Варто повторити домашнє завдання',
  'Багато запитань, висока зацікавленість',
  'Помітний прогрес порівняно з минулим тижнем',
];

const _flash = {'axes': '1', 'nums': '4-4', 'dir': 'Число → Абакус', 'mode': 'Тренування', 'ans': '20'};
const _shulte = {'mode': 'Цифри', 'field': '3×3', 'cnt': 'Прямий', 'other': '—'};

/// Заповнює [store] тестовими учнями, розкладом, заняттями за минулий і поточний
/// місяць, результатами тренажерів і прикладом фідбеку. Дати — відносно сьогодні.
void seedDemoData(AppStore store) {
  final rnd = Random(42);
  final now = today();
  final t = iso(now);
  final prevMonth = DateTime(now.year, now.month - 1);

  Student st(String name, int age, List<String> dirs, String level, {bool inclusion = false, String notes = ''}) =>
      Student(
        id: newId(),
        name: name,
        age: age,
        directions: dirs,
        level: level,
        parentContact: '+38050${100 + rnd.nextInt(900)}${1000 + rnd.nextInt(9000)}',
        notes: notes,
        inclusion: inclusion,
      );

  final ilia = st('Ілля Коваленко', 10, ['Roblox'], 'Lua, урок 23', notes: 'Любить ігри-перегони');
  final martin = st('Мартін Фюзеш', 8, ['МА'], 'Молодші друзі');
  final sofia = st('Софія Мельник', 9, ['Start & Click'], 'Scratch, модуль 2');
  final artem = st('Артем Бондар', 11, ['Roblox', 'МА'], 'Lua, урок 12 · Старші друзі');
  final zlata = st('Злата Ткаченко', 7, ['МА'], 'Прямий рахунок', inclusion: true, notes: 'Потрібні короткі перерви');
  final maksym = st('Максим Литвин', 12, ['Roblox'], 'DataStore, урок 31');
  final veronika = st('Вероніка Шевчук', 9, ['МА'], 'Комбінації');
  final danylo = st('Данило Кравець', 10, ['Start & Click'], 'Scratch, модуль 1');
  final ostap = st('Остап Гнатюк', 11, ['Roblox'], 'Lua, урок 5', notes: 'Сім’я у від’їзді до кінця місяця');
  final roman = st('Роман Савчук', 13, ['Roblox'], 'Курс завершено')..archived = true;
  final all = [ilia, martin, sofia, artem, zlata, maksym, veronika, danylo, ostap, roman];
  store.students.addAll(all);

  final from = iso(prevMonth);
  Schedule sch(Student s, int weekday, String time, String type) =>
      Schedule(id: newId(), weekday: weekday, time: time, studentId: s.id, type: type, from: from);
  store.schedules.addAll([
    sch(ilia, 0, '16:00', 'IT 60 день'),
    sch(ilia, 3, '16:00', 'IT 60 день'),
    sch(martin, 0, '17:30', 'МА 45 день'),
    sch(martin, 2, '17:30', 'МА 45 день'),
    sch(sofia, 1, '15:00', 'IT 45 день'),
    sch(artem, 1, '18:00', 'IT 60 ніч'),
    sch(artem, 4, '18:00', 'МА 45 ніч'),
    sch(zlata, 2, '16:00', 'МА 45 день'),
    sch(maksym, 5, '11:00', 'IT 90 день'),
    sch(veronika, 3, '17:30', 'МА 45 день'),
    sch(veronika, 5, '12:30', 'МА 45 день'),
    sch(danylo, 4, '16:00', 'IT 45 ПУ день'),
  ]);

  // Заняття з розкладу на минулий, поточний і наступний місяць.
  for (final m in [prevMonth, DateTime(now.year, now.month), DateTime(now.year, now.month + 1)]) {
    store.generateMonth(m);
  }

  // Остап давно не був: одне заняття понад 3 тижні тому.
  final ostapDay = iso(now.subtract(const Duration(days: 24)));
  store.lessons.add(
    Lesson(id: newId(), date: ostapDay, time: '15:00', studentId: ostap.id, type: 'IT 45 день', origDate: ostapDay),
  );

  // Минулі заняття: проведені з темами й описами, частина скасована, одне відпрацювання.
  final byStudent = <String, int>{};
  final past = store.lessons.where((l) => l.date.compareTo(t) < 0).toList()
    ..sort((a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}'));
  for (final l in past) {
    final s = store.student(l.studentId)!;
    final r = rnd.nextDouble();
    if (r < .08) {
      l.status = LessonStatus.cancelled;
      continue;
    }
    l.status = r < .12 ? LessonStatus.makeup : LessonStatus.done;
    final dir = l.type.startsWith('МА') ? 'МА' : s.directions.firstWhere((d) => d != 'МА', orElse: () => s.dir);
    final topics = _topics[dir] ?? _topics['Roblox']!;
    final n = byStudent.update(s.id, (v) => v + 1, ifAbsent: () => 0);
    l
      ..topic = topics[min(n ~/ 2, topics.length - 1)]
      ..description = rnd.nextDouble() < .8 ? _descriptions[rnd.nextInt(_descriptions.length)] : ''
      ..activity = 3 + rnd.nextInt(3);

    // Результати тренажерів на заняттях МА: час поступово покращується.
    if (dir == 'МА' && l.status.counts) {
      final k = byStudent[s.id]!;
      final base = 55.0 + s.age! * -1.5;
      store.results.add(
        TrainerResult(
          id: newId(),
          studentId: s.id,
          trainer: 'flash',
          settings: {..._flash},
          date: l.date,
          timeSec: _round(base * pow(.96, k) + rnd.nextDouble() * 4),
        ),
      );
      if (rnd.nextBool()) {
        store.results.add(
          TrainerResult(
            id: newId(),
            studentId: s.id,
            trainer: 'shulte',
            settings: {..._shulte},
            date: l.date,
            timeSec: _round(28 * pow(.95, k) + rnd.nextDouble() * 3),
          ),
        );
      }
    }
  }

  // Приклад готового фідбеку за минулий місяць.
  store.feedbacks['${ilia.id}|${ym(prevMonth)}'] = FeedbackDoc(
    studentId: ilia.id,
    month: ym(prevMonth),
    updated: iso(DateTime(now.year, now.month, 1)),
    text:
        'Добрий день!\n\n'
        'У ${_monthsLocative[prevMonth.month - 1]} Ілля вивчав основи мови Lua: змінні, умови та цикли, '
        'і вже застосовує їх у власних іграх у Roblox.\n\n'
        'Найкраще вдається логіка гри: Ілля сам пропонує, як ускладнити рівень. '
        'Варто ще потренувати уважність до деталей у коді — інколи через дрібну помилку скрипт не запускається.\n\n'
        'Удома радимо разом пограти в його гру й попросити пояснити, як вона працює. '
        'Це чудово закріплює матеріал.\n\n'
        'Дякую, що ви з нами!\nЗ повагою, Олена',
  );

  store.changed();
}

double _round(double v) => (v * 10).round() / 10;

const _monthsLocative = [
  'січні',
  'лютому',
  'березні',
  'квітні',
  'травні',
  'червні',
  'липні',
  'серпні',
  'вересні',
  'жовтні',
  'листопаді',
  'грудні',
];
