import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../utils.dart';
import '../theme.dart';

/// Кругла аватарка з ініціалами кольору напряму учня (.av).
class StudentAvatar extends StatelessWidget {
  const StudentAvatar(this.student, {super.key, this.size = 34});
  final Student? student;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tl.dir(student?.dir), shape: BoxShape.circle),
      child: Text(
        initials(student?.name ?? '?'),
        style: TextStyle(color: tl.card, fontWeight: FontWeight.w900, fontSize: size * .38),
      ),
    );
  }
}

/// Плашка напряму (.dpill).
class DirPill extends StatelessWidget {
  const DirPill(this.dir, {super.key});
  final String dir;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final c = tl.dir(dir);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(color: Color.lerp(tl.card, c, .15), borderRadius: BorderRadius.circular(99)),
      child: Text(
        dir,
        style: TextStyle(color: Color.lerp(tl.ink, c, .85), fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
    );
  }
}

/// Невелика мітка-тег (.tag); [strong] — заливка темним, як «інклюзія».
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.strong = false, this.color});
  final String text;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: color ?? (strong ? tl.dk : tl.xl), borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: TextStyle(color: strong ? tl.card : tl.ink, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
