import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../providers.dart';
import '../widgets/section_card.dart';

/// Налаштування фідбеку: тон, обсяг, мова, підпис, побажання. Лише на цьому телефоні.
class AiSettingsCard extends ConsumerStatefulWidget {
  const AiSettingsCard({super.key});

  @override
  ConsumerState<AiSettingsCard> createState() => _AiSettingsCardState();
}

class _AiSettingsCardState extends ConsumerState<AiSettingsCard> {
  late final AiSettings _ai = ref.read(deviceProvider).ai;
  late final _signature = TextEditingController(text: _ai.signature);
  late final _extra = TextEditingController(text: _ai.extra);
  late final _key = TextEditingController(text: _ai.apiKey);
  bool _showKey = false;

  @override
  void dispose() {
    _signature.dispose();
    _extra.dispose();
    _key.dispose();
    super.dispose();
  }

  void _update(void Function(AiSettings a) f) {
    f(_ai);
    ref.read(deviceProvider).saveAi();
  }

  Widget _select(String label, List<String> values, String value, void Function(String) set) =>
      DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [for (final v in values) DropdownMenuItem(value: v, child: Text(v))],
        onChanged: (v) => v == null ? null : _update((_) => set(v)),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Без ключа (і без Firebase) картка відкрита, щоб було видно, куди його вставити.
          initiallyExpanded: !ref.read(feedbackAiProvider).available,
          shape: const RoundedRectangleBorder(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Text('Налаштування фідбеку', style: Theme.of(context).textTheme.titleMedium),
          children: [
            Row(
              children: [
                Expanded(child: _select('Тон', AiSettings.tones.keys.toList(), _ai.tone, (v) => _ai.tone = v)),
                const SizedBox(width: 10),
                Expanded(child: _select('Обсяг', AiSettings.lengths.keys.toList(), _ai.length, (v) => _ai.length = v)),
              ],
            ),
            const SizedBox(height: 12),
            _select('Мова', AiSettings.languages, _ai.language, (v) => _ai.language = v),
            const SizedBox(height: 12),
            TextField(
              controller: _signature,
              decoration: const InputDecoration(labelText: 'Підпис', hintText: 'З повагою, Олена, викладачка Roblox'),
              onChanged: (v) => _update((a) => a.signature = v.trim()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _extra,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ваші побажання до стилю',
                hintText: 'Наприклад: додавай 1 емодзі',
                alignLabelWithHint: true,
              ),
              onChanged: (v) => _update((a) => a.extra = v.trim()),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 16),
            TextField(
              controller: _key,
              obscureText: !_showKey,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Ключ Gemini API',
                hintText: 'Вставте ключ з aistudio.google.com/apikey',
                helperText: 'Безкоштовний. Потрібен, поки не підключено Firebase.',
                suffixIcon: IconButton(
                  tooltip: _showKey ? 'Сховати' : 'Показати',
                  icon: Icon(_showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
              onChanged: (v) => _update((a) => a.apiKey = v.trim()),
            ),
            const SizedBox(height: 8),
            const MutedText('Усе тут, разом із ключем, зберігається лише на цьому телефоні.'),
          ],
        ),
      ),
    );
  }
}
