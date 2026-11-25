import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../data/store.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../theme.dart';
import '../widgets/lesson_row.dart';
import '../widgets/pickers.dart';
import '../widgets/section_card.dart';
import 'complete_sheet.dart';
import 'lesson_form_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _month = DateTime(today().year, today().month);
  String _selected = iso(today());

  void _setMonth(DateTime m) {
    final now = today();
    setState(() {
      _month = m;
      _selected = m.year == now.year && m.month == now.month ? iso(now) : iso(m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    if (!store.loaded) return const Center(child: CircularProgressIndicator());
    // Заняття з постійного розкладу з'являються для місяця, який переглядають.
    WidgetsBinding.instance.addPostFrameCallback((_) => store.generateMonth(_month));

    if (store.activeStudents.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Розклад',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MutedText('Спершу додайте учнів на сторінці «Налаштування».'),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => context.go('/settings'), child: const Text('До налаштувань')),
              ],
            ),
          ),
        ],
      );
    }

    final days = DateTime(_month.year, _month.month + 1, 0).day;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MonthSwitcher(month: _month, onChanged: _setMonth),
        const SizedBox(height: 6),
        MutedText('Темна смужка: 1–15 число, світла: 16–$days. Колір біля імені — напрям учня.'),
        const SizedBox(height: 10),
        _MonthGrid(month: _month, selected: _selected, store: store, onPick: (d) => setState(() => _selected = d)),
        const SizedBox(height: 14),
        _DayPanel(date: _selected, key: ValueKey(_selected)),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.selected, required this.store, required this.onPick});
  final DateTime month;
  final String selected;
  final AppStore store;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final last = DateTime(month.year, month.month + 1, 0);
    final rows = <Widget>[
      Row(
        children: [
          for (final w in weekdays)
            Expanded(
              child: Text(
                w,
                textAlign: TextAlign.center,
                style: TextStyle(color: tl.mut, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      const SizedBox(height: 4),
    ];
    for (
      var w = monday(DateTime(month.year, month.month));
      !w.isAfter(last);
      w = DateTime(w.year, w.month, w.day + 7)
    ) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: () {
                        final d = DateTime(w.year, w.month, w.day + i);
                        if (d.month != month.month) return const SizedBox();
                        final k = iso(d);
                        return _DayCell(
                          date: d,
                          lessons: store.lessonsOn(k),
                          store: store,
                          selected: k == selected,
                          onTap: () => onPick(k),
                        );
                      }(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.lessons,
    required this.store,
    required this.selected,
    required this.onTap,
  });
  final DateTime date;
  final List<Lesson> lessons;
  final AppStore store;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final isToday = date == today();
    const maxChips = 3;
    return Material(
      color: tl.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? tl.dk : tl.line, width: selected ? 2.5 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: date.day <= 15 ? tl.dk : tl.lt, width: 4)),
          ),
          padding: const EdgeInsets.all(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                  color: isToday ? tl.md : tl.ink,
                  fontSize: 13,
                ),
              ),
              for (final l in lessons.take(maxChips)) _Chip(l, store.student(l.studentId)),
              if (lessons.length > maxChips)
                Text('+${lessons.length - maxChips}', style: TextStyle(color: tl.mut, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.l, this.s);
  final Lesson l;
  final Student? s;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.fromLTRB(3, 1, 2, 1),
      decoration: BoxDecoration(
        color: tl.status(l.status),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: tl.dir(s?.dir), width: 3)),
      ),
      // Клітинка вузька: ім'я і прізвище — кожне на своєму рядку.
      child: Text(
        s?.name.trim().split(RegExp(r'\s+')).join('\n') ?? '—',
        maxLines: 3,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 9.5,
          height: 1.15,
          fontWeight: FontWeight.w700,
          decoration: l.status == LessonStatus.cancelled ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

/// Заняття обраного дня (замінює блок дня в таблиці).
class _DayPanel extends ConsumerStatefulWidget {
  const _DayPanel({super.key, required this.date});
  final String date;

  @override
  ConsumerState<_DayPanel> createState() => _DayPanelState();
}

class _DayPanelState extends ConsumerState<_DayPanel> {
  String? _addTime;
  int _addKey = 0;

  /// Наступний вільний час: через годину після останнього заняття.
  String _nextTime(List<Lesson> ls) {
    if (ls.isEmpty) return '16:00';
    final i = times.indexOf(ls.last.time);
    return i < 0 ? '16:00' : times[(i + 2).clamp(0, times.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final store = ref.watch(storeProvider);
    final device = ref.watch(deviceProvider);
    final lessons = store.lessonsOn(widget.date);
    final d = parseIso(widget.date);
    final addTime = _addTime ?? _nextTime(lessons);

    return SectionCard(
      title: '${weekdays[wd(d)]}, ${fd(widget.date)}',
      trailing: Text(
        'занять: ${lessons.length}',
        style: TextStyle(color: tl.mut, fontWeight: FontWeight.w700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lessons.isEmpty)
            const Padding(padding: EdgeInsets.only(bottom: 6), child: MutedText('Занять на цей день немає.')),
          for (final (i, l) in lessons.indexed)
            LessonRow(
              lesson: l,
              student: store.student(l.studentId),
              number: i + 1,
              onTap: () => openLessonForm(context, lesson: l),
              trailing: StatusButtons(
                status: l.status,
                onDone: () => l.status.counts ? store.toggleStatus(l, l.status) : showCompleteSheet(context, l),
                onCancel: () => store.toggleStatus(l, LessonStatus.cancelled),
              ),
            ),
          const SizedBox(height: 10),
          Divider(color: tl.line),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 104,
                child: TimeDropdown(
                  key: ValueKey('t$addTime$_addKey'),
                  value: addTime,
                  label: null,
                  onChanged: (v) => setState(() => _addTime = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<Student>(
                  key: ValueKey('s$_addKey'),
                  isExpanded: true,
                  hint: const Text('+ додати учня'),
                  menuMaxHeight: 400,
                  items: [
                    for (final s in store.activeStudents)
                      DropdownMenuItem(
                        value: s,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (s) {
                    if (s == null) return;
                    store.addLessons([
                      Lesson(id: newId(), date: widget.date, time: addTime, studentId: s.id, type: device.typeFor(s)),
                    ]);
                    setState(() {
                      _addTime = null;
                      _addKey++;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openLessonForm(context, date: widget.date),
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Нове заняття з усіма полями'),
            ),
          ),
          const MutedText(
            'Натисніть на заняття, щоб змінити дату, тип, опис або видалити його. '
            '✓ відкриває коротку форму теми й опису.',
          ),
        ],
      ),
    );
  }
}
