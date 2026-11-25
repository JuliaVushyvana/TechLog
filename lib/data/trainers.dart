/// Тренажери описані даними: новий тренажер додається сюди без нового екрана.
class TrainerField {
  const TrainerField(this.key, this.label, this.values);
  final String key;
  final String label;
  final List<String> values;
}

class Trainer {
  const Trainer(this.key, this.name, this.fields, {this.hasCorrect = false});
  final String key;
  final String name;
  final List<TrainerField> fields;
  final bool hasCorrect;

  /// Поле, що задає кількість відповідей (для «Правильно X з Y»).
  TrainerField? get answersField => fields.where((f) => f.key == 'ans').firstOrNull;

  String settingsKey(Map<String, String> s) => '$key|${fields.map((f) => s[f.key]).join('/')}';
  String settingsLabel(Map<String, String> s) => fields.map((f) => '${f.label}: ${s[f.key]}').join(', ');
  Map<String, String> defaults() => {for (final f in fields) f.key: f.values.first};
}

List<String> _rg(int a, int b) => [for (var i = a; i <= b; i++) '$i'];

const _speed = ['5', '4', '3', '2', '1', '0,9', '0,8', '0,7', '0,6', '0,5', '0,4', '0,3', '0,2', '0,1'];
const _formula = ['Прямий рахунок', 'Молодші друзі', 'Старші друзі', 'Комбінації'];

final trainers = <Trainer>[
  Trainer('flash', 'Флешкарти', [
    TrainerField('axes', 'Осі', _rg(1, 10)),
    const TrainerField('nums', 'Числа', ['4-4', '4-5', '4-6', '4-7', '4-8', '4-9']),
    const TrainerField('dir', 'Напрямок', ['Число → Абакус', 'Абакус → Число']),
    const TrainerField('mode', 'Режим', ['Тренування', 'Випробування']),
    TrainerField('ans', 'Відповіді', _rg(15, 50)),
  ], hasCorrect: true),
  Trainer('cols', 'Стовпці', [
    const TrainerField('form', 'Формула', _formula),
    const TrainerField('nums', 'Числа', ['1-9', '10-99', '100-999', '1000-9999']),
    TrainerField('terms', 'К-ть доданків', _rg(2, 10)),
    TrainerField('ans', 'Відповіді', _rg(5, 30)),
  ], hasCorrect: true),
  Trainer('mental', 'Ментальна арифметика', [
    const TrainerField('form', 'Формула', _formula),
    const TrainerField('num', 'Число', ['1-9', '10-99', '100-999']),
    TrainerField('acts', 'Дії', _rg(2, 25)),
    TrainerField('ans', 'Відповіді', _rg(5, 30)),
    const TrainerField('spd', 'Швидкість, с', _speed),
  ], hasCorrect: true),
  const Trainer('shulte', 'Таблиця Шульте', [
    TrainerField('mode', 'Режим', ['Цифри', 'Літери']),
    TrainerField('field', 'Поле', ['3×3', '4×4', '5×5', '6×6', '7×7', '8×8']),
    TrainerField('cnt', 'Рахунок', ['Прямий', 'Зворотній', 'Випадковий']),
    TrainerField('other', 'Інше', ['—', 'Перемішувати при натисканні', 'Сховати підказки']),
  ]),
  Trainer('cat', 'Знайди кіберкішку', [
    const TrainerField('field', 'Поле', ['3×3', '5×5', '7×7']),
    TrainerField('steps', 'Кроки', _rg(8, 20)),
    const TrainerField('spd', 'Швидкість', _speed),
    TrainerField('hint', 'Підказка', _rg(1, 5)),
  ]),
  Trainer('pair', 'Знайди пару', [TrainerField('cards', 'Картки', _rg(8, 20))]),
];

Trainer trainerBy(String key) => trainers.firstWhere((t) => t.key == key, orElse: () => trainers.first);
