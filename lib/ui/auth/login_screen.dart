import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth.dart';
import '../../data/demo_data.dart';
import '../../providers.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider).login(email: _email.text, password: _password.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Debug: вхід у демо-акаунт з тестовими даними (створюється при першому вході).
  Future<void> _demo() async {
    // Після входу роутер закриє цей екран, тому працюємо через контейнер, а не ref.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      final auth = container.read(authProvider);
      try {
        await auth.login(email: demoEmail, password: demoPassword);
      } on AuthException {
        await auth.register(name: demoName, email: demoEmail, password: demoPassword);
      }
      final store = container.read(storeProvider);
      await store.load();
      if (store.students.isEmpty) seedDemoData(store);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (validateEmail(email) != null) {
      showError(context, 'Спершу введіть свій email у поле вище.');
      return;
    }
    try {
      await ref.read(authProvider).sendPasswordReset(email);
      if (mounted) showError(context, 'Лист для скидання пароля надіслано на $email.');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Вхід',
      subtitle: 'Увійдіть, щоб побачити свій розклад і учнів.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    suffixIcon: IconButton(
                      tooltip: _hide ? 'Показати пароль' : 'Сховати пароль',
                      icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  obscureText: _hide,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => v == null || v.isEmpty ? 'Введіть пароль' : null,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _reset, child: const Text('Забули пароль?')),
        ),
        BusyButton(busy: _busy, label: 'Увійти', onPressed: _submit),
        const SizedBox(height: 8),
        TextButton(onPressed: () => context.go('/register'), child: const Text('Немає акаунта? Зареєструватися')),
        if (kDebugMode) ...[
          const Divider(height: 24),
          OutlinedButton.icon(
            onPressed: _busy ? null : _demo,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Демо-акаунт з тестовими даними'),
          ),
        ],
      ],
    );
  }
}
