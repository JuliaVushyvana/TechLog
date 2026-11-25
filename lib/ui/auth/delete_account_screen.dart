import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../theme.dart';
import '../widgets/section_card.dart';
import 'auth_scaffold.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_form.currentState!.validate()) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити акаунт назавжди?'),
        content: const Text('Цю дію не можна скасувати.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    setState(() => _busy = true);
    try {
      // Після видалення роутер сам перекине на екран входу.
      await ref.read(authProvider).deleteAccount(_password.text);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    final error = Theme.of(context).colorScheme.error;
    final email = ref.watch(authProvider).user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Видалення акаунта')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Що буде видалено',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final t in const [
                  'Усі учні, заняття й постійний розклад',
                  'Результати тренажерів і графіки прогресу',
                  'Архів фідбеків для батьків',
                  'Типи занять, грейд і налаштування на цьому телефоні',
                  'Сам акаунт — увійти з ним більше не вийде',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.remove_circle_outline, size: 18, color: error),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Відновити дані після видалення неможливо.',
                  style: TextStyle(color: error, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Підтвердіть паролем',
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Акаунт: $email', style: TextStyle(color: tl.mut)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? 'Введіть пароль' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: error),
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Видалити акаунт і всі дані'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
