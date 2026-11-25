import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../providers.dart';
import '../theme.dart';

/// Відкриває форму нового учня або редагування [student] поверх нижнього меню.
Future<void> openStudentForm(BuildContext context, [Student? student]) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => StudentFormScreen(student: student)));

/// Підтвердження й видалення учня з усією історією. Повертає true, якщо видалено.
Future<bool> confirmDeleteStudent(BuildContext context, WidgetRef ref, Student s) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Видалити ${s.name}?'),
      content: const Text(
        'Разом з учнем буде видалено всі його заняття, результати тренажерів і фідбеки. '
        'Якщо історію треба зберегти, краще перенесіть учня в архів.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Видалити'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  ref.read(storeProvider).deleteStudent(s.id);
  return true;
}

class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.student});
  final Student? student;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student?.name);
  late final _age = TextEditingController(text: widget.student?.age?.toString());
  late final _level = TextEditingController(text: widget.student?.level);
  late final _contact = TextEditingController(text: widget.student?.parentContact);
  late final _notes = TextEditingController(text: widget.student?.notes);
  late final Set<String> _dirs = {...?widget.student?.directions};
  late bool _inclusion = widget.student?.inclusion ?? false;
  bool _dirError = false;

  @override
  void dispose() {
    for (final c in [_name, _age, _level, _contact, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    setState(() => _dirError = _dirs.isEmpty);
    if (!_form.currentState!.validate() || _dirs.isEmpty) return;
    final store = ref.read(storeProvider);
    final dirs = directions.where(_dirs.contains).toList();
    final s = widget.student ?? Student(id: newId(), name: '');
    s
      ..name = _name.text.trim()
      ..age = int.tryParse(_age.text)
      ..directions = dirs
      ..level = _level.text.trim()
      ..parentContact = _contact.text.trim()
      ..notes = _notes.text.trim()
      ..inclusion = _inclusion;
    if (widget.student == null) {
      store.addStudent(s);
    } else {
      store.changed();
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final editing = widget.student != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Редагувати учня' : 'Новий учень'),
        actions: [TextButton(onPressed: _save, child: const Text('Зберегти'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Ім’я та прізвище'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Введіть ім’я' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              decoration: const InputDecoration(labelText: 'Вік'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = int.parse(v);
                return n < 3 || n > 99 ? 'Від 3 до 99' : null;
              },
            ),
            const SizedBox(height: 16),
            Text('Напрям', style: TextStyle(color: tl.mut, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final d in directions)
                  FilterChip(
                    label: Text(d),
                    selected: _dirs.contains(d),
                    selectedColor: Color.lerp(tl.card, tl.dir(d), .2),
                    onSelected: (on) => setState(() {
                      on ? _dirs.add(d) : _dirs.remove(d);
                      _dirError = false;
                    }),
                  ),
              ],
            ),
            if (_dirError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Оберіть хоча б один напрям',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _level,
              decoration: const InputDecoration(
                labelText: 'Поточний рівень або урок',
                hintText: 'Наприклад: Lua, урок 23',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(labelText: 'Контакт батьків', hintText: 'Телефон, Viber або Telegram'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Інклюзія', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('AI писатиме фідбек особливо делікатно'),
              value: _inclusion,
              onChanged: (v) => setState(() => _inclusion = v),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Нотатки', alignLabelWithHint: true),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Зберегти')),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  if (await confirmDeleteStudent(context, ref, widget.student!)) nav.pop(true);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Видалити учня'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
