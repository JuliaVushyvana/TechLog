import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/auth.dart';
import 'data/demo_data.dart';
import 'data/device_settings.dart';
import 'data/feedback_ai.dart';
import 'data/gemini_ai.dart';
import 'data/repository.dart';
import 'data/store.dart';

/// Підміняється в main() готовим екземпляром.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final authProvider = ChangeNotifierProvider<AuthService>((ref) => LocalAuthService(ref.watch(prefsProvider))..init());

final dataRepoProvider = Provider<DataRepository>((ref) => LocalDataRepository(ref.watch(prefsProvider)));

/// Дані поточного вчителя; перестворюється при вході / виході.
final storeProvider = ChangeNotifierProvider<AppStore>((ref) {
  final teacherId = ref.watch(authProvider.select((a) => a.user?.id));
  final email = ref.read(authProvider).user?.email;
  final store = AppStore(ref.watch(dataRepoProvider), teacherId);
  store.load().then((_) {
    // Debug: порожній демо-акаунт одразу заповнюється тестовими даними.
    if (kDebugMode && !store.isDisposed && email == demoEmail && store.students.isEmpty) seedDemoData(store);
  });
  return store;
});

final deviceProvider = ChangeNotifierProvider<DeviceSettings>((ref) {
  final teacherId = ref.watch(authProvider.select((a) => a.user?.id));
  final email = ref.read(authProvider).user?.email;
  // Debug: демо-акаунт за замовчуванням Senior.
  final grade = kDebugMode && email == demoEmail ? 'Senior' : 'Junior';
  return DeviceSettings(ref.watch(prefsProvider), teacherId, defaultGrade: grade);
});

/// true, якщо Firebase успішно ініціалізовано в main(). Підміняється там же.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Генератор фідбеку: Gemini через Firebase AI Logic, якщо Firebase налаштовано;
/// інакше — Gemini API з ключем з налаштувань фідбеку; інакше AI недоступний.
final feedbackAiProvider = Provider<FeedbackAi>((ref) {
  if (ref.watch(firebaseReadyProvider)) return const GeminiFeedbackAi();
  final key = ref.watch(deviceProvider.select((d) => d.ai.apiKey));
  return key.isNotEmpty ? GeminiKeyFeedbackAi(key) : const UnconfiguredAi();
});
