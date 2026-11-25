import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/auth.dart';
import 'data/device_settings.dart';
import 'data/feedback_ai.dart';
import 'data/repository.dart';
import 'data/store.dart';

/// Підміняється в main() готовим екземпляром.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final authProvider = ChangeNotifierProvider<AuthService>((ref) => LocalAuthService(ref.watch(prefsProvider))..init());

final dataRepoProvider = Provider<DataRepository>((ref) => LocalDataRepository(ref.watch(prefsProvider)));

/// Дані поточного вчителя; перестворюється при вході / виході.
final storeProvider = ChangeNotifierProvider<AppStore>((ref) {
  final teacherId = ref.watch(authProvider.select((a) => a.user?.id));
  return AppStore(ref.watch(dataRepoProvider), teacherId)..load();
});

final deviceProvider = ChangeNotifierProvider<DeviceSettings>((ref) {
  final teacherId = ref.watch(authProvider.select((a) => a.user?.id));
  return DeviceSettings(ref.watch(prefsProvider), teacherId);
});

/// Генератор фідбеку. Після підключення Firebase тут буде Gemini (firebase_ai).
final feedbackAiProvider = Provider<FeedbackAi>((ref) => const UnconfiguredAi());
