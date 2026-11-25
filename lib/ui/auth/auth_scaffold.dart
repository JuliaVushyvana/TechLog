import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logo.dart';

/// Спільна оболонка екранів входу й реєстрації: логотип і картка з формою.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children});
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: Logo(size: 44)),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(subtitle, style: TextStyle(color: tl.mut)),
                          const SizedBox(height: 18),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Введіть email';
  if (!_emailRe.hasMatch(v.trim())) return 'Невірний формат email';
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Введіть пароль';
  if (v.length < 6) return 'Щонайменше 6 символів';
  return null;
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
}

/// Кнопка з індикатором завантаження.
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.busy, required this.label, required this.onPressed});
  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
          : Text(label),
    );
  }
}
