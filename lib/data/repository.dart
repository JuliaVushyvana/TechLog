import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Сховище даних вчителя (users/{teacherId}). Зараз локальне,
/// після підключення Firebase його замінить реалізація на Cloud Firestore.
abstract class DataRepository {
  Future<Map<String, dynamic>> load(String teacherId);
  Future<void> save(String teacherId, Map<String, dynamic> data);
}

class LocalDataRepository implements DataRepository {
  LocalDataRepository(this._prefs);
  final SharedPreferences _prefs;

  // Суфікс _{teacherId} потрібен, щоб видалення акаунта прибрало ці дані.
  String _key(String id) => 'tl_data_$id';

  @override
  Future<Map<String, dynamic>> load(String teacherId) async {
    final raw = _prefs.getString(_key(teacherId));
    return raw == null ? {} : (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  @override
  Future<void> save(String teacherId, Map<String, dynamic> data) => _prefs.setString(_key(teacherId), jsonEncode(data));
}
