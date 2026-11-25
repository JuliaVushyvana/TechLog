import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../theme.dart';
import '../widgets/pickers.dart';
import '../widgets/section_card.dart';
import '../widgets/student_bits.dart';

/// Постійний розклад: заняття, що щотижня самі з'являються в календарі.
class ScheduleSection extends ConsumerWidget {
  const ScheduleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tl = context.tl;
    final store = ref.watch(storeProvider);
    final list = store.schedules.where((s) => store.student(s.studentId) != null).toList()
      ..sort((a, b) => a.weekday != b.weekday ? a.weekday - b.weekday : a.time.compareTo(b.time));

    return SectionCard(
      title: 'Постійний розклад',
      trailing: Text(
        'на тиждень: ${list.length}',
        style: TextStyle(color: tl.mut, fontWeight: FontWeight.w700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MutedText(
            'Внесіть розклад один раз, і заняття самі з’являтимуться в календарі щотижня. '
            'Зміни тут стосуються майбутніх занять без теми й опису.',
          ),
          const SizedBox(height: 8),
          for (final s in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: StudentAvatar(store.student(s.studentId)),
              title: Text(
                '${weekdays[s.weekday]} ${s.time} · ${store.student(s.studentId)!.name}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${s.type} · діє з ${fd(s.from)}'),
              onTap: () => _openForm(context, s),
              trailing: IconButton(
                tooltip: 'Видалити',
                icon: const Icon(Icons.close),
                onPressed: () => _confirmDelete(context, ref, s),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: store.activeStudents.isEmpty ? null : () => _openForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Додати заняття в розклад'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Schedule s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити з постійного розкладу?'),
        content: const Text('Майбутні заплановані заняття буде прибрано, проведені залишаться.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Видалити')),
        ],
      ),
    );
    if (ok == true) ref.read(storeProvider).deleteSchedule(s.id);
  }

  void _openForm(BuildContext context, Schedule? s) => showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ScheduleForm(s),
  );
}

class _ScheduleForm extends ConsumerStatefulWidget {
  const _ScheduleForm(this.schedule);
  final Schedule? schedule;

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  final _form = GlobalKey<FormState>();
  late int _weekday = widget.schedule?.weekday ?? 0;
  late String _time = widget.schedule?.time ?? '16:00';
  Student? _student;
  late String _type = widget.schedule?.type ?? '';
  late String _from = widget.schedule?.from ?? iso(DateTime(today().year, today().month));

  @override
  void initState() {
    super.initState();
    final id = widget.schedule?.studentId;
    if (id != null) _student = ref.read(storeProvider).student(id);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = ref.read(storeProvider);
    final type = _type.isEmpty ? ref.read(deviceProvider).typeFor(_student) : _type;
    final s = widget.schedule;
    if (s == null) {
      store.addSchedule(
        Schedule(id: newId(), weekday: _weekday, time: _time, studentId: _student!.id, type: type, from: _from),
      );
    } else {
      s
        ..weekday = _weekday
        ..time = _time
        ..studentId = _student!.id
        ..type = type
        ..from = _from;
      store.updateSchedule(s);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final types = ref.watch(deviceProvider).types;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.schedule == null ? 'Нове заняття в розкладі' : 'Заняття в розкладі',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _weekday,
                      decoration: const InputDecoration(labelText: 'День'),
                      items: [for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(weekdays[i]))],
                      onChanged: (v) => setState(() => _weekday = v ?? 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TimeDropdown(value: _time, onChanged: (v) => setState(() => _time = v)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StudentDropdown(
                students: store.activeStudents,
                value: _student,
                onChanged: (s) => setState(() {
                  _student = s;
                  _type = ref.read(deviceProvider).typeFor(s);
                }),
              ),
              const SizedBox(height: 12),
              TypeDropdown(
                key: ValueKey(_type),
                types: types,
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: parseIso(_from),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _from = iso(d));
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Діє з', suffixIcon: Icon(Icons.event_outlined)),
                  child: Text('${fd(_from)}.${parseIso(_from).year}'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Зберегти')),
            ],
          ),
        ),
      ),
    );
  }
}
