import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../schedule/complete_sheet.dart';
import '../schedule/lesson_form_screen.dart';
import '../theme.dart';
import '../widgets/lesson_row.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/student_bits.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tl = context.tl;
    final store = ref.watch(storeProvider);
    if (!store.loaded) return const Center(child: CircularProgressIndicator());
    final now = today();
    WidgetsBinding.instance.addPostFrameCallback((_) => store.generateMonth(now));

    final t = iso(now);
    final month = store.lessonsInMonth(ym(now));
    int count(LessonStatus s) => month.where((l) => l.status == s).length;
    final todayLessons = store.lessonsOn(t);
    final idle = store.idleStudents();
    final name = ref.watch(authProvider).user?.name.split(' ').first ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Привіт, $name!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        SectionCard(
          title: 'Цей місяць · ${months[now.month - 1]}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${count(LessonStatus.done)}',
                      label: 'проведено',
                      color: tl.dk,
                      filled: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(value: '${count(LessonStatus.planned)}', label: 'заплановано', color: tl.md),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatTile(value: '${count(LessonStatus.cancelled)}', label: 'скасовано', color: tl.other),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(value: '${count(LessonStatus.makeup)}', label: 'відпрацювання', color: tl.ma),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              MutedText('Учнів: ${store.activeStudents.length}. Результатів на тренажерах: ${store.results.length}.'),
              const SizedBox(height: 6),
              _Split(month.where((l) => l.status.counts).toList()),
            ],
          ),
        ),
        SectionCard(
          title: 'Сьогодні, ${weekdays[wd(now)]} ${fd(t)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (store.activeStudents.isEmpty) ...[
                const MutedText('Почніть з того, що додасте учнів на сторінці «Налаштування».'),
                const SizedBox(height: 10),
                FilledButton(onPressed: () => context.go('/settings'), child: const Text('Додати учнів')),
              ] else ...[
                if (todayLessons.isEmpty) const MutedText('Сьогодні занять немає.'),
                for (final l in todayLessons)
                  LessonRow(
                    lesson: l,
                    student: store.student(l.studentId),
                    onTap: () => openLessonForm(context, lesson: l),
                    trailing: StatusButtons(
                      status: l.status,
                      onDone: () => l.status.counts ? store.toggleStatus(l, l.status) : showCompleteSheet(context, l),
                      onCancel: () => store.toggleStatus(l, LessonStatus.cancelled),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openLessonForm(context, date: t),
                        icon: const Icon(Icons.add),
                        label: const Text('Нове заняття'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/schedule'),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Розклад'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (idle.isNotEmpty)
          SectionCard(
            title: 'Давно не було занять',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MutedText('Учні без проведених занять понад 2 тижні.'),
                for (final (s, last) in idle)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: StudentAvatar(s),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(last == null ? 'занять ще не було' : 'останнє: ${fd(last)}'),
                    trailing: Icon(Icons.chevron_right, color: tl.mut),
                    onTap: () => context.go('/settings/student/${s.id}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Частка IT / МА і денних / нічних серед проведених занять.
class _Split extends StatelessWidget {
  const _Split(this.done);
  final List<Lesson> done;

  @override
  Widget build(BuildContext context) {
    if (done.isEmpty) return const SizedBox();
    int c(bool Function(String) f) => done.where((l) => f(l.type)).length;
    final parts = {
      'IT': c((t) => t.startsWith('IT')),
      'МА': c((t) => t.startsWith('МА')),
      'день': c((t) => t.contains('день')),
      'ніч': c((t) => t.contains('ніч')),
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in parts.entries)
          if (e.value > 0) TagChip('${e.key}: ${e.value}'),
      ],
    );
  }
}
