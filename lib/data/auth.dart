import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_data.dart';
import 'models.dart';

class AppUser {
  const AppUser({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Інтерфейс авторизації. Зараз реалізований локально ([LocalAuthService]),
/// після `flutterfire configure` його замінить реалізація на Firebase Auth.
abstract class AuthService extends ChangeNotifier {
  /// false, доки не перевірено, чи вчитель уже увійшов (показується splash).
  bool get ready;
  AppUser? get user;

  Future<void> init();
  Future<void> register({required String name, required String email, required String password});
  Future<void> login({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> logout();

  /// Перевіряє пароль і видаляє акаунт разом з усіма даними вчителя.
  Future<void> deleteAccount(String password);
}

class LocalAuthService extends AuthService {
  LocalAuthService(this._prefs);

  final SharedPreferences _prefs;
  static const _usersKey = 'tl_users';
  static const _sessionKey = 'tl_session';

  bool _ready = false;
  AppUser? _user;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  bool get ready => _ready;
  @override
  AppUser? get user => _user;

  Map<String, dynamic> get _users => (jsonDecode(_prefs.getString(_usersKey) ?? '{}') as Map).cast<String, dynamic>();

  Future<void> _saveUsers(Map<String, dynamic> users) => _prefs.setString(_usersKey, jsonEncode(users));

  String _hash(String salt, String password) => sha256.convert(utf8.encode('$salt:$password')).toString();

  AppUser _toUser(String email, Map u) => AppUser(id: u['id'], name: u['name'], email: email);

  @override
  Future<void> init() async {
    // Коротка пауза, щоб splash встиг показатися.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (_disposed) return;
    if (kDebugMode) await _ensureDemoAccount();
    final email = _prefs.getString(_sessionKey);
    final u = email == null ? null : _users[email];
    _user = u == null ? null : _toUser(email!, u);
    _ready = true;
    notifyListeners();
  }

  /// Debug: демо-акаунт вчителя зареєстрований одразу, щоб у нього можна було
  /// просто увійти. Тестові дані додаються при першому вході (див. storeProvider).
  Future<void> _ensureDemoAccount() async {
    final users = _users;
    if (users.containsKey(demoEmail)) return;
    final salt = newId();
    users[demoEmail] = {
      'id': newId(),
      'name': demoName,
      'salt': salt,
      'hash': _hash(salt, demoPassword),
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _saveUsers(users);
  }

  @override
  Future<void> register({required String name, required String email, required String password}) async {
    email = email.trim().toLowerCase();
    final users = _users;
    if (users.containsKey(email)) throw const AuthException('Акаунт з таким email уже існує.');
    final salt = newId();
    users[email] = {
      'id': newId(),
      'name': name.trim(),
      'salt': salt,
      'hash': _hash(salt, password),
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _saveUsers(users);
    await _prefs.setString(_sessionKey, email);
    _user = _toUser(email, users[email]);
    notifyListeners();
  }

  @override
  Future<void> login({required String email, required String password}) async {
    email = email.trim().toLowerCase();
    final u = _users[email];
    if (u == null || _hash(u['salt'], password) != u['hash']) {
      throw const AuthException('Невірний email або пароль.');
    }
    await _prefs.setString(_sessionKey, email);
    _user = _toUser(email, u);
    notifyListeners();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw const AuthException(
      'Скидання пароля листом запрацює після підключення Firebase. Поки що створіть новий акаунт.',
    );
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_sessionKey);
    _user = null;
    notifyListeners();
  }

  @override
  Future<void> deleteAccount(String password) async {
    final current = _user;
    if (current == null) return;
    final users = _users;
    final u = users[current.email];
    if (u == null || _hash(u['salt'], password) != u['hash']) {
      throw const AuthException('Пароль невірний.');
    }
    // Дані вчителя зберігаються під ключами з його id.
    for (final k in _prefs.getKeys().where((k) => k.endsWith('_${current.id}')).toList()) {
      await _prefs.remove(k);
    }
    users.remove(current.email);
    await _saveUsers(users);
    await _prefs.remove(_sessionKey);
    _user = null;
    notifyListeners();
  }
}
