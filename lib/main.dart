import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';
import 'router.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final firebaseReady = await _initFirebase();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs), firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const TeachLogApp(),
    ),
  );
}

/// Ініціалізує Firebase. Поки проєкт не налаштовано (`flutterfire configure`),
/// застосунок працює без нього, а AI-фідбек показує підказку.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    debugPrint('Firebase не налаштовано: $e');
    return false;
  }
}

class TeachLogApp extends ConsumerWidget {
  const TeachLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TeachLog',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
