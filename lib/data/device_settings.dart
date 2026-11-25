import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const defaultLessonTypes = [
  'IT 45 день',
  'IT 45 ніч',
  'IT 60 день',
  'IT 60 ніч',
  'IT 90 день',
  'IT 90 ніч',
  'IT 45 ПУ день',
  'IT 45 ПУ ніч',
  'МА 45 день',
  'МА 45 ніч',
  'МА 90 день',
];
const defaultGrades = ['Junior', 'Middle', 'Senior'];

/// Налаштування, що живуть лише на цьому телефоні (shared_preferences):
/// типи занять, грейд, параметри AI-фідбеку.
class DeviceSettings extends ChangeNotifier {
  DeviceSettings(this._prefs, String? teacherId, {String defaultGrade = 'Junior'}) : _suffix = '_${teacherId ?? 'guest'}' {
    types = _prefs.getStringList('tl_types$_suffix') ?? [...defaultLessonTypes];
    grade = _prefs.getString('tl_grade$_suffix') ?? defaultGrade;
    final ai = _prefs.getString('tl_ai$_suffix');
    this.ai = ai == null ? AiSettings() : AiSettings.fromJson(jsonDecode(ai));
  }

  final SharedPreferences _prefs;

  // Суфікс з id вчителя — щоб «Видалити акаунт» прибрав і ці ключі.
  final String _suffix;

  late List<String> types;
  late String grade;
  late AiSettings ai;

  void addType(String t) {
    t = t.trim();
    if (t.isEmpty || types.contains(t)) return;
    types = [...types, t];
    _prefs.setStringList('tl_types$_suffix', types);
    notifyListeners();
  }

  void removeType(String t) {
    types = types.where((x) => x != t).toList();
    _prefs.setStringList('tl_types$_suffix', types);
    notifyListeners();
  }

  void setGrade(String g) {
    grade = g.trim().isEmpty ? 'Junior' : g.trim();
    _prefs.setString('tl_grade$_suffix', grade);
    notifyListeners();
  }

  void saveAi() {
    _prefs.setString('tl_ai$_suffix', jsonEncode(ai.toJson()));
    notifyListeners();
  }

  /// Тип за замовчуванням для учня: МА → перший тип «МА…», інакше перший «IT…».
  String typeFor(Student? s) {
    final prefix = s?.dir == 'МА' ? 'МА' : 'IT';
    return types.where((t) => t.startsWith(prefix)).firstOrNull ?? types.firstOrNull ?? '';
  }
}
