import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../data/store.dart';
import '../../data/trainers.dart';
import '../../providers.dart';
import '../../utils.dart';
import '../theme.dart';
import '../widgets/pickers.dart';
import '../widgets/section_card.dart';

class TrainersScreen extends ConsumerStatefulWidget {
  const TrainersScreen({super.key});

  @override
  ConsumerState<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends ConsumerState<TrainersScreen> {
  String? _studentId;
  Trainer _trainer = trainers.first;
  Map<String, String> _values = trainers.first.defaults();
  final _time = TextEditingController();
  final _form = GlobalKey<FormState>();

  /// Набір налаштувань, для якого показано графік.
  String? _chartKey;

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  void _setTrainer(Trainer t) => setState(() {
    _trainer = t;
    _values = t.defaults();
    _chartKey = null;
  });

  void _sameAsLastTime(AppStore store) {
    final last = store.lastSettings(_studentId!, _trainer.key);
    if (last == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Для цього учня ще немає результатів на цьому тренажері.')));
      return;
    }
    setState(() => _values = {..._trainer.defaults(), ...last});
  }

  Future<void> _save(AppStore store) async {
    if (!_form.currentState!.validate()) return;
    final time = double.parse(_time.text.replaceAll(',', '.'));
    final r = TrainerResult(
      id: newId(),
      studentId: _studentId!,
      trainer: _trainer.key,
      settings: {..._values},
      date: iso(today()),
      timeSec: time,
    );
    final record = store.addResult(r);
    _time.clear();
    FocusScope.of(context).unfocus();
    setState(() => _chartKey = _trainer.settingsKey(r.settings));
    if (record) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Text('🏆', style: TextStyle(fontSize: 40)),
          title: const Text('Новий рекорд!'),
          content: Text('${fmtSec(time)} с — найкращий час на цих налаштуваннях.', textAlign: TextAlign.center),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Супер'))],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Збережено: ${fmtSec(time)} с')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    if (!store.loaded) return const Center(child: CircularProgressIndicator());
    final students = store.activeStudents;
    if (students.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Тренажери',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MutedText('Спершу додайте учнів на сторінці «Налаштування».'),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => context.go('/settings'), child: const Text('До налаштувань')),
              ],
            ),
          ),
        ],
      );
    }
    // За замовчуванням — перший учень МА, бо тренажери саме для них.
    final student =
        store.student(_studentId ?? '') ??
        students.firstWhere((s) => s.directions.contains('МА'), orElse: () => students.first);
    _studentId = student.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _newResultCard(store, students, student),
        _ProgressCard(
          store: store,
          studentId: student.id,
          trainer: _trainer,
          selectedKey: _chartKey,
          onKey: (k) => setState(() => _chartKey = k),
        ),
        _RecordsCard(store: store, studentId: student.id),
        _HistoryCard(store: store, studentId: student.id),
      ],
    );
  }

  Widget _newResultCard(AppStore store, List<Student> students, Student student) {
    final tl = context.tl;
    return SectionCard(
      title: 'Новий результат',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudentDropdown(
              key: ValueKey('st${student.id}'),
              students: students,
              value: student,
              onChanged: (s) => setState(() {
                _studentId = s.id;
                _chartKey = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Trainer>(
              initialValue: _trainer,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Тренажер'),
              items: [for (final t in trainers) DropdownMenuItem(value: t, child: Text(t.name))],
              onChanged: (t) => t == null ? null : _setTrainer(t),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (final f in _trainer.fields)
                      SizedBox(
                        width: f.values.any((v) => v.length > 14) ? c.maxWidth : w,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('${_trainer.key}.${f.key}.${_values[f.key]}'),
                          initialValue: _values[f.key],
                          isExpanded: true,
                          menuMaxHeight: 360,
                          decoration: InputDecoration(labelText: f.label),
                          items: [
                            for (final v in f.values)
                              DropdownMenuItem(
                                value: v,
                                child: Text(v, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) => setState(() => _values[f.key] = v ?? _values[f.key]!),
                        ),
                      ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _sameAsLastTime(store),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Як минулого разу'),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _time,
                    decoration: const InputDecoration(labelText: 'Час, с'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    validator: (v) {
                      final t = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return t == null || t <= 0 ? 'Введіть час' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => _save(store), child: const Text('Зберегти результат')),
            const SizedBox(height: 6),
            Text(
              'Тренування і випробування рахуються окремо, як і різні налаштування.',
              style: TextStyle(color: tl.mut, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Графік часу для пари «тренажер + налаштування».
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.store,
    required this.studentId,
    required this.trainer,
    required this.selectedKey,
    required this.onKey,
  });
  final AppStore store;
  final String studentId;
  final Trainer trainer;
  final String? selectedKey;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final mine = store.results.where((r) => r.studentId == studentId && r.trainer == trainer.key);
    // Набори налаштувань, від найсвіжішого.
    final labels = <String, String>{};
    for (final r in mine.toList().reversed) {
      labels.putIfAbsent(trainer.settingsKey(r.settings), () => trainer.settingsLabel(r.settings));
    }
    if (labels.isEmpty) {
      return SectionCard(
        title: 'Прогрес · ${trainer.name}',
        child: const MutedText(
          'Збережіть перший результат — тут з’явиться графік. Лінія будується окремо '
          'для кожного набору налаштувань, бо час на них непорівнянний.',
        ),
      );
    }
    final key = labels.containsKey(selectedKey) ? selectedKey! : labels.keys.first;
    final a = store.attempts(studentId, key);
    final bestTime = a.map((r) => r.timeSec).reduce(min);
    final first = a.first.timeSec;
    final last = a.last.timeSec;
    final change = a.length > 1 ? ((first - last) / first * 100).round() : null;
    final maxY = a.map((r) => r.timeSec).reduce(max);
    final minY = bestTime;
    final pad = max((maxY - minY) * .2, 1.0);

    return SectionCard(
      title: 'Прогрес · ${trainer.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (labels.length > 1)
            DropdownButtonFormField<String>(
              key: ValueKey(key),
              initialValue: key,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Налаштування'),
              items: [
                for (final e in labels.entries)
                  DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => v == null ? null : onKey(v),
            )
          else
            Text(labels.values.first, style: TextStyle(color: tl.mut, fontSize: 13)),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: max(0, minY - pad),
                maxY: maxY + pad,
                minX: 0,
                maxX: max(1, a.length - 1).toDouble(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: tl.line, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => tl.dk,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${fmtSec(s.y)} с\n${fd(a[s.x.toInt()].date)}',
                          TextStyle(color: tl.card, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: max(1, (a.length / 5).ceil()).toDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= a.length || v != i.toDouble()) return const SizedBox();
                        return Text(fd(a[i].date), style: TextStyle(color: tl.mut, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, meta) => v == meta.max || v == meta.min
                          ? const SizedBox()
                          : Text(fmtSec(v), style: TextStyle(color: tl.mut, fontSize: 10)),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (final (i, r) in a.indexed) FlSpot(i.toDouble(), r.timeSec)],
                    color: tl.dk,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(show: true, color: tl.xl),
                    dotData: FlDotData(
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: spot.y == bestTime ? 5.5 : 3.5,
                        color: spot.y == bestTime ? tl.acc : tl.dk,
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Рекорд: '),
                    TextSpan(
                      text: '${fmtSec(bestTime)} с',
                      style: TextStyle(color: tl.md, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Text('спроб: ${a.length}', style: TextStyle(color: tl.mut)),
              if (change != null)
                Text(
                  change >= 0 ? 'швидше на $change%' : 'повільніше на ${-change}%',
                  style: TextStyle(color: change >= 0 ? tl.md : tl.mut, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Особисті рекорди учня для кожної пари «тренажер + налаштування».
class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.store, required this.studentId});
  final AppStore store;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final best = <String, TrainerResult>{};
    for (final r in store.results.where((r) => r.studentId == studentId)) {
      final k = trainerBy(r.trainer).settingsKey(r.settings);
      if (best[k] == null || r.timeSec < best[k]!.timeSec) best[k] = r;
    }
    if (best.isEmpty) return const SizedBox();
    final list = best.values.toList()..sort((a, b) => a.trainer.compareTo(b.trainer));
    return SectionCard(
      title: 'Рекорди',
      child: Column(
        children: [
          for (final r in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Text('🏆', style: TextStyle(fontSize: 20, color: tl.md)),
              title: Text(trainerBy(r.trainer).name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(trainerBy(r.trainer).settingsLabel(r.settings)),
              trailing: Text(
                '${fmtSec(r.timeSec)} с',
                style: TextStyle(color: tl.md, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.store, required this.studentId});
  final AppStore store;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final list = store.results.where((r) => r.studentId == studentId).toList().reversed.toList();
    return SectionCard(
      title: 'Історія результатів',
      child: list.isEmpty
          ? const MutedText('Історія порожня.')
          : Column(
              children: [
                for (final (i, r) in list.indexed) ...[
                  if (i > 0) Divider(height: 1, color: tl.line),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${trainerBy(r.trainer).name} · ${fmtSec(r.timeSec)} с',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${fd(r.date)} · ${trainerBy(r.trainer).settingsLabel(r.settings)}'),
                    trailing: IconButton(
                      tooltip: 'Видалити',
                      icon: const Icon(Icons.close),
                      onPressed: () => store.deleteResult(r.id),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
