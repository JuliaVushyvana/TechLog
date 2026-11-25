String pad2(int n) => n.toString().padLeft(2, '0');

/// yyyy-MM-dd
String iso(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';

DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// yyyy-MM
String ym(DateTime d) => '${d.year}-${pad2(d.month)}';

/// dd.MM
String fd(String isoDate) {
  final d = parseIso(isoDate);
  return '${pad2(d.day)}.${pad2(d.month)}';
}

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime monday(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// 0 = Пн … 6 = Нд
int wd(DateTime d) => d.weekday - 1;

const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
const months = [
  'Січень',
  'Лютий',
  'Березень',
  'Квітень',
  'Травень',
  'Червень',
  'Липень',
  'Серпень',
  'Вересень',
  'Жовтень',
  'Листопад',
  'Грудень',
];

final times = [for (var i = 0; i < 48; i++) '${pad2(i ~/ 2)}:${i.isOdd ? '30' : '00'}'];

String initials(String name) =>
    name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

String fmtSec(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
