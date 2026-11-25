import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../utils.dart';
import '../theme.dart';

/// Вибір часу з кроком 30 хв (як у таблиці). Нестандартний час теж показується.
class TimeDropdown extends StatelessWidget {
  const TimeDropdown({super.key, required this.value, required this.onChanged, this.label = 'Час'});
  final String value;
  final ValueChanged<String> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final items = times.contains(value) ? times : ([...times, value]..sort());
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      menuMaxHeight: 320,
      items: [for (final t in items) DropdownMenuItem(value: t, child: Text(t))],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

/// Вибір учня з активних (архівні не показуються, крім уже обраного).
class StudentDropdown extends StatelessWidget {
  const StudentDropdown({
    super.key,
    required this.students,
    required this.value,
    required this.onChanged,
    this.label = 'Учень',
  });
  final List<Student> students;
  final Student? value;
  final ValueChanged<Student> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final list = [...students, if (value != null && !students.contains(value)) value!];
    return DropdownButtonFormField<Student>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      menuMaxHeight: 400,
      validator: (v) => v == null ? 'Оберіть учня' : null,
      items: [
        for (final s in list)
          DropdownMenuItem(
            value: s,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

/// Вибір типу заняття зі списку вчителя.
class TypeDropdown extends StatelessWidget {
  const TypeDropdown({
    super.key,
    required this.types,
    required this.value,
    required this.onChanged,
    this.label = 'Тип заняття',
  });
  final List<String> types;
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final items = [if (value.isNotEmpty && !types.contains(value)) value, ...types];
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      menuMaxHeight: 400,
      items: [for (final t in items) DropdownMenuItem(value: t, child: Text(t))],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

/// Активність на занятті 1–5.
class ActivityPicker extends StatelessWidget {
  const ActivityPicker({super.key, required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Активність', style: TextStyle(color: tl.mut, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 1; i <= 5; i++)
              ChoiceChip(label: Text('$i'), selected: value == i, onSelected: (on) => onChanged(on ? i : null)),
          ],
        ),
      ],
    );
  }
}

/// Перемикач місяця: ‹ Листопад 2026 › і «Сьогодні».
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.month, required this.onChanged});
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = today();
    final isCurrent = month.year == now.year && month.month == now.month;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: 'Попередній місяць',
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${months[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton.outlined(
          tooltip: 'Наступний місяць',
          onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
        if (!isCurrent) ...[
          const SizedBox(width: 6),
          TextButton(onPressed: () => onChanged(DateTime(now.year, now.month)), child: const Text('Сьогодні')),
        ],
      ],
    );
  }
}
