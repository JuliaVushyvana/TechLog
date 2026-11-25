import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets/logo.dart';

/// Поки показується splash, AuthService перевіряє, чи вчитель уже увійшов;
/// після цього роутер сам веде на головний екран або на вхід.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = TL.light;
    return Scaffold(
      backgroundColor: c.dk,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(28)),
              child: const LogoMark(size: 72),
            ),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Teach'),
                  TextSpan(
                    text: 'Log',
                    style: TextStyle(color: c.lt),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Журнал занять вчителя',
              style: TextStyle(color: c.lt, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.lt)),
          ],
        ),
      ),
    );
  }
}
