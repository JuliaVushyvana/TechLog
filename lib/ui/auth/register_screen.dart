import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider).register(name: _name.text, email: _email.text, password: _password.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Реєстрація',
      subtitle: 'Створіть акаунт вчителя. Учні й заняття будуть видні лише вам.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Ім’я'),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().length < 2 ? 'Введіть ім’я' : null,
                ),
                const SizedBox(height: 12),
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
                  decoration: const InputDecoration(labelText: 'Пароль', helperText: 'Щонайменше 6 символів'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  decoration: const InputDecoration(labelText: 'Підтвердження пароля'),
                  obscureText: true,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => v != _password.text ? 'Паролі не збігаються' : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        BusyButton(busy: _busy, label: 'Зареєструватися', onPressed: _submit),
        const SizedBox(height: 8),
        TextButton(onPressed: () => context.go('/login'), child: const Text('Вже маєте акаунт? Увійти')),
      ],
    );
  }
}
