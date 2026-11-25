import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../data/trainers.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../theme.dart';
import '../widgets/section_card.dart';
import '../widgets/student_bits.dart';
import 'student_form_screen.dart';

class StudentCardScreen extends ConsumerWidget {
  const StudentCardScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final s = store.student(studentId);
    if (s == null) {
      // Учня видалено (наприклад, з форми редагування) — повертаємось до списку.
      if (store.loaded) WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/settings'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tl = context.tl;
    final lessons = store.lessonsOf(s.id);
    final results = store.resultsOf(s.id);
    final feedbacks = store.feedbacksOf(s.id);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.name),
          actions: [
            IconButton(
              tooltip: 'Редагувати',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => openStudentForm(context, s),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'archive') store.setArchived(s, !s.archived);
                if (v == 'delete') await confirmDeleteStudent(context, ref, s);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'archive', child: Text(s.archived ? 'Повернути з архіву' : 'В архів')),
                const PopupMenuItem(value: 'delete', child: Text('Видалити')),
              ],
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _Header(s)),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsDelegate(
                ColoredBox(
                  color: tl.bg,
                  child: TabBar(
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: [
                      Tab(text: 'Заняття (${lessons.length})'),
                      Tab(text: 'Тренажери (${results.length})'),
                      Tab(text: 'Фідбеки (${feedbacks.length})'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(children: [_LessonsTab(lessons), _ResultsTab(results), _FeedbacksTab(feedbacks)]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.s);
  final Student s;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    Widget info(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tl.mut),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(s, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final d in s.directions) DirPill(d),
                        if (s.inclusion) const TagChip('інклюзія', strong: true),
                        if (s.archived) const TagChip('архів'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (s.age != null) info(Icons.cake_outlined, '${s.age} р.'),
          if (s.level.isNotEmpty) info(Icons.school_outlined, s.level),
          if (s.parentContact.isNotEmpty) info(Icons.phone_outlined, s.parentContact),
          if (s.notes.isNotEmpty) info(Icons.notes_outlined, s.notes),
        ],
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate(this.child);
  final Widget child;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(_TabsDelegate oldDelegate) => oldDelegate.child != child;
}

Widget _empty(String text) => Padding(
  padding: const EdgeInsets.all(24),
  child: MutedText(text, align: TextAlign.center),
);

class _LessonsTab extends StatelessWidget {
  const _LessonsTab(this.lessons);
  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return _empty('Занять поки немає. Вони з’являться, коли ви додасте учня в розклад.');
    final tl = context.tl;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (_, i) {
        final l = lessons[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tl.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tl.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${fd(l.date)}, ${l.time}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.type, style: TextStyle(color: tl.mut)),
                  ),
                  TagChip(l.status.label, color: tl.status(l.status)),
                ],
              ),
              if (l.topic.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.topic)),
              if (l.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(l.description, style: TextStyle(color: tl.mut)),
                ),
              if (l.activity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Активність: ${l.activity}/5', style: TextStyle(color: tl.md)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab(this.results);
  final List<TrainerResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return _empty('Результатів на тренажерах ще немає.');
    final tl = context.tl;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: tl.line),
      itemBuilder: (_, i) {
        final r = results[i];
        final t = trainerBy(r.trainer);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${t.name} · ${fmtSec(r.timeSec)} с', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${fd(r.date)} · ${t.settingsLabel(r.settings)}'),
          trailing: r.correct == null ? null : Text('${r.correct}${r.total == null ? '' : ' з ${r.total}'}'),
        );
      },
    );
  }
}

class _FeedbacksTab extends StatelessWidget {
  const _FeedbacksTab(this.feedbacks);
  final List<FeedbackDoc> feedbacks;

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) return _empty('Згенерованих фідбеків ще немає.');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final f in feedbacks)
          SectionCard(
            title: () {
              final p = f.month.split('-');
              return '${months[int.parse(p[1]) - 1]} ${p[0]}';
            }(),
            child: Text(f.text),
          ),
      ],
    );
  }
}
