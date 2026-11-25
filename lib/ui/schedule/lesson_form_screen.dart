import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../theme.dart';
import '../widgets/pickers.dart';

/// Відкриває форму нового заняття на [date] або редагування [lesson].
Future<void> openLessonForm(BuildContext context, {Lesson? lesson, String? date}) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LessonFormScreen(lesson: lesson, date: date),
      ),
    );

/// Поле теми з автопідказкою з попередніх тем.
class TopicField extends StatelessWidget {
  const TopicField({super.key, required this.initial, required this.topics, required this.onChanged});
  final String initial;
  final List<String> topics;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initial),
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.isEmpty) return const [];
        return topics.where((t) => t.toLowerCase().contains(q) && t != v.text).take(6);
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
        controller: controller,
        focusNode: focus,
        decoration: const InputDecoration(labelText: 'Тема', hintText: 'Наприклад: Lua, сл. 23'),
        onChanged: onChanged,
        onFieldSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

class LessonFormScreen extends ConsumerStatefulWidget {
  const LessonFormScreen({super.key, this.lesson, this.date});
  final Lesson? lesson;
  final String? date;

  @override
  ConsumerState<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends ConsumerState<LessonFormScreen> {
  final _form = GlobalKey<FormState>();
  late String _date = widget.lesson?.date ?? widget.date ?? iso(today());
  late String _time = widget.lesson?.time ?? '16:00';
  Student? _student;
  late String _type = widget.lesson?.type ?? '';
  late LessonStatus _status = widget.lesson?.status ?? LessonStatus.planned;
  late String _topic = widget.lesson?.topic ?? '';
  late final _desc = TextEditingController(text: widget.lesson?.description);
  late int? _activity = widget.lesson?.activity;
  int _repeat = 1;

  @override
  void initState() {
    super.initState();
    final store = ref.read(storeProvider);
    _student = widget.lesson == null ? null : store.student(widget.lesson!.studentId);
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseIso(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = iso(d));
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = ref.read(storeProvider);
    final type = _type.isEmpty ? ref.read(deviceProvider).typeFor(_student) : _type;
    final l = widget.lesson;
    if (l != null) {
      l
        ..date = _date
        ..time = _time
        ..studentId = _student!.id
        ..type = type
        ..status = _status
        ..topic = _topic.trim()
        ..description = _desc.text.trim()
        ..activity = _activity;
      store.changed();
    } else {
      final start = parseIso(_date);
      store.addLessons([
        for (var i = 0; i < _repeat; i++)
          Lesson(
            id: newId(),
            date: iso(DateTime(start.year, start.month, start.day + 7 * i)),
            time: _time,
            studentId: _student!.id,
            type: type,
            status: i == 0 ? _status : LessonStatus.planned,
            topic: i == 0 ? _topic.trim() : '',
            description: i == 0 ? _desc.text.trim() : '',
            activity: i == 0 ? _activity : null,
          ),
      ]);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l = widget.lesson!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити це заняття?'),
        content: Text(
          l.scheduleId != null
              ? 'Заняття з постійного розкладу буде прибрано лише на цю дату. Інші тижні не зміняться.'
              : 'Інші заняття не зміняться.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Видалити')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(storeProvider).deleteLesson(l.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final store = ref.watch(storeProvider);
    final types = ref.watch(deviceProvider).types;
    final editing = widget.lesson != null;
    final date = parseIso(_date);

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Заняття' : 'Нове заняття'),
        actions: [TextButton(onPressed: _save, child: const Text('Зберегти'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.lesson?.scheduleId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Заняття з постійного розкладу',
                  style: TextStyle(color: tl.md, fontWeight: FontWeight.w700),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Дата', suffixIcon: Icon(Icons.event_outlined)),
                      child: Text('${weekdays[wd(date)]}, ${fd(_date)}.${date.year}'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
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
                if (!editing) _type = ref.read(deviceProvider).typeFor(s);
              }),
            ),
            const SizedBox(height: 12),
            TypeDropdown(key: ValueKey(_type), types: types, value: _type, onChanged: (v) => setState(() => _type = v)),
            const SizedBox(height: 12),
            DropdownButtonFormField<LessonStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Статус'),
              items: [for (final s in LessonStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            TopicField(initial: _topic, topics: store.topics, onChanged: (v) => _topic = v),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Опис / що вийшло',
                hintText: 'Джерело для AI-фідбеку',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            ActivityPicker(value: _activity, onChanged: (v) => setState(() => _activity = v)),
            if (!editing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text('Повторювати щотижня, разів', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  IconButton.outlined(
                    onPressed: _repeat > 1 ? () => setState(() => _repeat--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$_repeat',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: _repeat < 20 ? () => setState(() => _repeat++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Зберегти')),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Видалити заняття'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
