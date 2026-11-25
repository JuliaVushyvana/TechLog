import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../theme.dart';
import 'student_bits.dart';

/// Рядок заняття (.lrow): смужка кольору напряму, час, аватар, ім'я, тип і тема.
class LessonRow extends StatelessWidget {
  const LessonRow({super.key, required this.lesson, required this.student, this.number, this.onTap, this.trailing});

  final Lesson lesson;
  final Student? student;
  final int? number;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final d = tl.dir(student?.dir);
    final cancelled = lesson.status == LessonStatus.cancelled;
    final bg = switch (lesson.status) {
      LessonStatus.planned => Color.lerp(tl.card, d, .08)!,
      _ => tl.status(lesson.status),
    };
    final details = [lesson.type, if (lesson.topic.isNotEmpty) lesson.topic].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: d, width: 5)),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                if (number != null) ...[
                  SizedBox(
                    width: 18,
                    child: Text(
                      '$number',
                      style: TextStyle(color: tl.mut, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: d, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    lesson.time,
                    style: TextStyle(
                      color: tl.card,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StudentAvatar(student, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student?.name ?? '—',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: cancelled ? TextDecoration.lineThrough : null,
                          decorationColor: tl.mut,
                        ),
                      ),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tl.mut, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопки статусу ✓ / ✗ (.stb): повторне натискання знімає статус.
class StatusButtons extends StatelessWidget {
  const StatusButtons({super.key, required this.status, required this.onDone, required this.onCancel});
  final LessonStatus status;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    Widget btn(String label, String tip, bool on, Color onColor, VoidCallback tap) => Tooltip(
      message: tip,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: tap,
        child: Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? onColor : tl.card,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? onColor : tl.line),
          ),
          child: Text(
            label,
            style: TextStyle(color: on ? tl.card : tl.mut, fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(
          status == LessonStatus.makeup ? '↻' : '✓',
          'Проведено',
          status == LessonStatus.done || status == LessonStatus.makeup,
          tl.md,
          onDone,
        ),
        const SizedBox(width: 4),
        btn('✗', 'Скасовано', status == LessonStatus.cancelled, tl.mut, onCancel),
      ],
    );
  }
}
