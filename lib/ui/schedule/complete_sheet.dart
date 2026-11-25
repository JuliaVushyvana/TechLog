import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../providers.dart';
import '../widgets/pickers.dart';
import 'lesson_form_screen.dart';

/// Швидке завершення: тема, опис і активність, після чого заняття стає «проведено».
Future<void> showCompleteSheet(BuildContext context, Lesson lesson) => showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _CompleteSheet(lesson),
);

class _CompleteSheet extends ConsumerStatefulWidget {
  const _CompleteSheet(this.lesson);
  final Lesson lesson;

  @override
  ConsumerState<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends ConsumerState<_CompleteSheet> {
  late String _topic = widget.lesson.topic;
  late final _desc = TextEditingController(text: widget.lesson.description);
  late int? _activity = widget.lesson.activity;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    widget.lesson
      ..status = LessonStatus.done
      ..topic = _topic.trim()
      ..description = _desc.text.trim()
      ..activity = _activity;
    ref.read(storeProvider).changed();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final s = store.student(widget.lesson.studentId);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Проведено: ${s?.name ?? ''}', style: Theme.of(context).textTheme.titleLarge),
            Text('${widget.lesson.time} · ${widget.lesson.type}'),
            const SizedBox(height: 14),
            TopicField(initial: _topic, topics: store.topics, onChanged: (v) => _topic = v),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Що вийшло',
                hintText: 'Наприклад: швидко розібрався з циклами',
              ),
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            ActivityPicker(value: _activity, onChanged: (v) => setState(() => _activity = v)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Зберегти як проведене')),
          ],
        ),
      ),
    );
  }
}
