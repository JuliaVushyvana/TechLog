import 'package:flutter/material.dart';

import '../theme.dart';

/// Кольорова плитка статистики (.stat): велике число й підпис.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, required this.color, this.filled = false});
  final String value;
  final String label;
  final Color color;

  /// Перша плитка в дизайні залита темним.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final fg = filled ? tl.card : color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: filled ? color : Color.lerp(tl.card, color, .13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(color: fg, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1),
          ),
          Text(
            label,
            style: TextStyle(color: filled ? tl.card : Color.lerp(tl.ink, color, .7), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
