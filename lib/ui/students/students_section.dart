import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../providers.dart';
import '../theme.dart';
import '../widgets/section_card.dart';
import '../widgets/student_bits.dart';
import 'student_form_screen.dart';

/// Блок «Учні» на сторінці налаштувань: пошук, фільтр за напрямом, список.
class StudentsSection extends ConsumerStatefulWidget {
  const StudentsSection({super.key});

  @override
  ConsumerState<StudentsSection> createState() => _StudentsSectionState();
}

class _StudentsSectionState extends ConsumerState<StudentsSection> {
  String _query = '';
  String? _dir;
  bool _archive = false;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final store = ref.watch(storeProvider);
    final q = _query.trim().toLowerCase();
    final list =
        store.students
            .where(
              (s) =>
                  s.archived == _archive &&
                  s.name.toLowerCase().contains(q) &&
                  (_dir == null || s.directions.contains(_dir)),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final archivedCount = store.students.where((s) => s.archived).length;

    return SectionCard(
      title: 'Учні',
      trailing: FilledButton.icon(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        onPressed: () => openStudentForm(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Додати'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'Пошук за ім’ям', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final d in [null, ...directions])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(d ?? 'Усі'),
                      selected: _dir == d,
                      onSelected: (_) => setState(() => _dir = d),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: MutedText(
                store.students.isEmpty
                    ? 'Учнів поки немає. Натисніть «Додати», щоб внести першого.'
                    : 'Нікого не знайдено.',
              ),
            ),
          for (final (i, s) in list.indexed) ...[
            if (i > 0) Divider(height: 1, color: tl.line),
            _StudentTile(s, done: store.doneThisMonth(s.id)),
          ],
          if (archivedCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _archive = !_archive),
                icon: Icon(_archive ? Icons.people_outline : Icons.inventory_2_outlined, size: 18),
                label: Text(_archive ? 'Повернутися до активних' : 'Архів ($archivedCount)'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile(this.s, {required this.done});
  final Student s;
  final int done;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/settings/student/${s.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            StudentAvatar(s),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (s.inclusion) const TagChip('інклюзія', strong: true),
                      for (final d in s.directions) DirPill(d),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (s.age != null) '${s.age} р.',
                      if (s.level.isNotEmpty) s.level,
                      'цього місяця: $done',
                    ].join(' · '),
                    style: TextStyle(color: tl.mut, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: tl.mut),
          ],
        ),
      ),
    );
  }
}
