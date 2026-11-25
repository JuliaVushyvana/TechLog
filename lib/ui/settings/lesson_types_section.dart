import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../widgets/section_card.dart';

class LessonTypesSection extends ConsumerStatefulWidget {
  const LessonTypesSection({super.key});

  @override
  ConsumerState<LessonTypesSection> createState() => _LessonTypesSectionState();
}

class _LessonTypesSectionState extends ConsumerState<LessonTypesSection> {
  final _new = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  void _add() {
    ref.read(deviceProvider).addType(_new.text);
    _new.clear();
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(deviceProvider);
    return SectionCard(
      title: 'Типи занять',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MutedText('Зберігаються лише на цьому телефоні. Вже створені заняття свій тип не втратять.'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in device.types)
                InputChip(
                  label: Text(t),
                  onDeleted: () => device.removeType(t),
                  deleteButtonTooltipMessage: 'Видалити',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _new,
                  decoration: const InputDecoration(hintText: 'Наприклад: IT 60 день'),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _add, child: const Text('Додати')),
            ],
          ),
        ],
      ),
    );
  }
}
