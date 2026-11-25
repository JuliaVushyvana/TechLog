import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Картка розділу: заголовок з повернутим квадратиком-маркером, як у дизайні.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.trailing, required this.child});
  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Transform.rotate(
                    angle: 12 * pi / 180,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: tl.dk, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleLarge)),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Приглушений допоміжний текст (.mut).
class MutedText extends StatelessWidget {
  const MutedText(this.text, {super.key, this.align});
  final String text;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: TextStyle(color: context.tl.mut, fontSize: 13.5),
  );
}
