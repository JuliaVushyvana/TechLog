import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_data.dart';
import '../../data/device_settings.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../students/students_section.dart';
import '../theme.dart';
import '../widgets/section_card.dart';
import 'lesson_types_section.dart';
import 'schedule_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tl = context.tl;
    final user = ref.watch(authProvider).user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Профіль',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: tl.dk,
                    child: Text(
                      initials(user?.name ?? '?'),
                      style: TextStyle(color: tl.card, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(user?.email ?? '', style: TextStyle(color: tl.mut)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _GradePicker(),
            ],
          ),
        ),
        const ScheduleSection(),
        const StudentsSection(),
        const LessonTypesSection(),
        if (kDebugMode)
          SectionCard(
            title: 'Тестові дані',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MutedText(
                  'Лише в debug-збірці. Додає 10 учнів, постійний розклад, заняття за минулий і поточний місяць, '
                  'результати тренажерів і приклад фідбеку.',
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _seed(context, ref),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Додати тестові дані'),
                ),
              ],
            ),
          ),
        SectionCard(
          title: 'Акаунт',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () => ref.read(authProvider).logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Вийти'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => context.go('/settings/delete-account'),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Видалити акаунт'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _seed(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Додати тестові дані?'),
      content: const Text('Їх буде додано до ваших даних. Прибрати можна, видаливши тестових учнів або акаунт.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Додати')),
      ],
    ),
  );
  if (ok != true) return;
  seedDemoData(ref.read(storeProvider));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Тестові дані додано')));
  }
}

/// Грейд: зі списку або своя назва.
class _GradePicker extends ConsumerWidget {
  const _GradePicker();

  static const _custom = '__custom__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProvider);
    final grades = [...defaultGrades, if (!defaultGrades.contains(device.grade)) device.grade];
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Грейд',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<String>(
        value: device.grade,
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          for (final g in grades) DropdownMenuItem(value: g, child: Text(g)),
          const DropdownMenuItem(value: _custom, child: Text('Своя назва…')),
        ],
        onChanged: (v) async {
          if (v == null) return;
          if (v != _custom) return device.setGrade(v);
          final controller = TextEditingController();
          final name = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Свій грейд'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Наприклад: Lead'),
                onSubmitted: (t) => Navigator.pop(ctx, t),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
                FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Зберегти')),
              ],
            ),
          );
          controller.dispose();
          if (name != null && name.trim().isNotEmpty) device.setGrade(name);
        },
      ),
    );
  }
}
