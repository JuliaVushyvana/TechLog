import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/logo.dart';

/// Головний екран з шапкою-логотипом і нижнім меню з п'яти вкладок.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Головна'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Розклад'),
    (Icons.calculate_outlined, Icons.calculate_rounded, 'Тренажери'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Фідбеки'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Налаштування'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Logo(), centerTitle: false, bottom: const GradientStripe()),
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          for (final (icon, selected, label) in _tabs)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
