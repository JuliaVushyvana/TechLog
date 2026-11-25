import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/feedback_ai.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../theme.dart';
import '../widgets/pickers.dart';
import '../widgets/section_card.dart';
import '../widgets/student_bits.dart';
import 'ai_settings_card.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  DateTime _month = DateTime(today().year, today().month);
  String? _studentId;
  final _text = TextEditingController();
  final Set<String> _busy = {};
  Timer? _saveTimer;

  /// Запам'ятовується в build: у dispose звертатися до ref не можна.
  AppStore? _store;

  /// Для якого учня/місяця зараз завантажено текст у поле.
  String? _loadedKey;

  String get _ym => ym(_month);

  @override
  void dispose() {
    _flush();
    _text.dispose();
    super.dispose();
  }

  /// Відкладене збереження тексту, що редагується.
  void _onEdit(String v) {
    setState(() {}); // увімкнути / вимкнути «Копіювати» й «Поділитися»
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _flush);
  }

  void _flush() {
    if (_saveTimer?.isActive ?? false) _saveTimer!.cancel();
    _saveTimer = null;
    final key = _loadedKey;
    if (key == null) return;
    final p = key.split('|');
    final store = _store;
    if (store == null) return;
    if ((store.feedback(p[0], p[1])?.text ?? '') != _text.text) store.setFeedback(p[0], p[1], _text.text);
  }

  void _select({String? studentId, DateTime? month}) {
    _flush();
    setState(() {
      if (month != null) _month = month;
      if (studentId != null) _studentId = studentId;
      _loadedKey = null;
    });
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<bool> _generate(Student s) async {
    final store = ref.read(storeProvider);
    final ai = ref.read(feedbackAiProvider);
    final data = store.feedbackData(s, _ym);
    setState(() => _busy.add(s.id));
    try {
      final text = await ai.generate(
        system: buildSystemPrompt(ref.read(deviceProvider).ai),
        prompt: buildUserPrompt(data),
      );
      store.setFeedback(s.id, data.month, text.trim());
      if (mounted && _loadedKey == '${s.id}|${data.month}') _text.text = text.trim();
      return true;
    } catch (e) {
      final reason = '$e'.replaceFirst('Exception: ', '');
      if (mounted) _snack(e is AiUnavailable ? reason : 'Не вдалося згенерувати фідбек: $reason');
      return false;
    } finally {
      if (mounted) setState(() => _busy.remove(s.id));
    }
  }

  Future<void> _generateAll(List<Student> list, AppStore store) async {
    final todo = list.where((s) => store.feedback(s.id, _ym) == null).toList();
    if (todo.isEmpty) return _snack('Фідбеки для всіх учнів за цей місяць уже є.');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Згенерувати для всіх?'),
        content: Text(
          'Буде створено ${todo.length} фідбек(ів) для учнів, у яких його ще немає. '
          'Кожен потім варто вичитати перед відправкою.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Згенерувати')),
        ],
      ),
    );
    if (ok != true) return;
    for (final s in todo) {
      if (!mounted || !await _generate(s)) break;
    }
  }

  Future<void> _copy(String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack(done);
  }

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final store = ref.watch(storeProvider);
    _store = store;
    final ai = ref.watch(feedbackAiProvider);
    if (!store.loaded) return const Center(child: CircularProgressIndicator());

    final list = store.studentsWithLessons(_ym);
    final selected = list.where((s) => s.id == _studentId).firstOrNull ?? list.firstOrNull;
    final key = selected == null ? null : '${selected.id}|$_ym';
    if (key != _loadedKey) {
      _loadedKey = key;
      _text.text = selected == null ? '' : store.feedback(selected.id, _ym)?.text ?? '';
    }
    final ready = list.where((s) => store.feedback(s.id, _ym) != null).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MonthSwitcher(
          month: _month,
          onChanged: (m) => _select(month: m),
        ),
        const SizedBox(height: 12),
        if (!ai.available)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: tl.warn, borderRadius: BorderRadius.circular(14)),
            child: const Text(
              'AI ще не підключено. Вставте безкоштовний ключ Gemini API у «Налаштуваннях фідбеку» внизу '
              '(його можна отримати на aistudio.google.com/apikey). Або натисніть «Скопіювати запит», '
              'вставте його в чат з AI, а готовий текст — у поле фідбеку.',
            ),
          ),
        if (list.isEmpty)
          const SectionCard(
            title: 'Фідбеки',
            child: MutedText('У цьому місяці ще немає проведених занять, тож писати фідбек нема з чого.'),
          )
        else ...[
          SectionCard(
            title: 'Учні, що мали заняття',
            trailing: Text(
              '$ready/${list.length}',
              style: TextStyle(color: tl.mut, fontWeight: FontWeight.w800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in list)
                      _StudentPill(
                        student: s,
                        selected: s == selected,
                        ready: store.feedback(s.id, _ym) != null,
                        busy: _busy.contains(s.id),
                        onTap: () => _select(studentId: s.id),
                      ),
                  ],
                ),
                if (ai.available) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy.isEmpty ? () => _generateAll(list, store) : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Згенерувати для всіх'),
                  ),
                ],
              ],
            ),
          ),
          if (selected != null) _editor(store, selected, ai),
        ],
        const AiSettingsCard(),
      ],
    );
  }

  Widget _editor(AppStore store, Student s, FeedbackAi ai) {
    final tl = context.tl;
    final data = store.feedbackData(s, _ym);
    final doc = store.feedback(s.id, _ym);
    final busy = _busy.contains(s.id);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StudentAvatar(s, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                    Wrap(spacing: 4, children: [for (final d in s.directions) DirPill(d)]),
                  ],
                ),
              ),
            ],
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Нотатки за місяць: ${data.lessons.length} зан.',
                style: TextStyle(color: tl.mut, fontSize: 14),
              ),
              children: [
                for (final l in data.lessons)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 46,
                          child: Text(fd(l.date), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: Text(
                            [l.status.label, l.topic, l.description].where((x) => x.isNotEmpty).join(' · '),
                            style: TextStyle(
                              color: l.status == LessonStatus.cancelled ? tl.mut : tl.ink,
                              decoration: l.status == LessonStatus.cancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (data.tooLittle)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: tl.xl, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Даних замало: менше двох проведених занять з темою чи описом. '
                'Фідбек вийде загальним — допишіть теми в «Розкладі».',
                style: TextStyle(color: tl.dk, fontSize: 13),
              ),
            ),
          TextField(
            controller: _text,
            onChanged: _onEdit,
            minLines: 8,
            maxLines: 20,
            decoration: InputDecoration(
              labelText: 'Фідбек для батьків',
              alignLabelWithHint: true,
              hintText: ai.available ? 'Натисніть «Згенерувати»' : 'Вставте сюди текст або напишіть свій',
              helperText: 'Можна редагувати — зберігається автоматично. Батькам нічого не надсилається без вас.',
              helperMaxLines: 2,
            ),
          ),
          if (doc != null)
            Padding(padding: const EdgeInsets.only(top: 4), child: MutedText('Останні зміни: ${fd(doc.updated)}')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : () => _generate(s),
            icon: busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(busy ? 'Генерую…' : (doc == null ? 'Згенерувати' : 'Перегенерувати')),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _text.text.trim().isEmpty ? null : () => _copy(_text.text, 'Фідбек скопійовано'),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Копіювати'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _text.text.trim().isEmpty
                      ? null
                      : () => SharePlus.instance.share(
                          ShareParams(text: _text.text, subject: 'Фідбек: ${s.name}, ${data.monthLabel}'),
                        ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Поділитися'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _copy(
              '${buildSystemPrompt(ref.read(deviceProvider).ai)}\n\n---\n\n${buildUserPrompt(data)}',
              'Запит скопійовано. Прізвище й контакти в нього не потрапили.',
            ),
            icon: const Icon(Icons.content_paste_go, size: 18),
            label: const Text('Скопіювати запит для AI'),
          ),
        ],
      ),
    );
  }
}

class _StudentPill extends StatelessWidget {
  const _StudentPill({
    required this.student,
    required this.selected,
    required this.ready,
    required this.busy,
    required this.onTap,
  });
  final Student student;
  final bool selected;
  final bool ready;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Material(
      color: ready ? tl.xl : tl.card,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? tl.dk : tl.line, width: selected ? 2 : 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudentAvatar(student, size: 26),
              const SizedBox(width: 6),
              Text(student.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              if (busy)
                const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
              else if (ready)
                Icon(Icons.check_circle, size: 16, color: tl.md),
            ],
          ),
        ),
      ),
    );
  }
}
