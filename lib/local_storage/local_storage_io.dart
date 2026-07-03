import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class LocalKeyValueStore {
  LocalKeyValueStore() : _preferences = null;

  LocalKeyValueStore._(this._preferences);

  final SharedPreferences? _preferences;
  final Map<String, String> _memory = <String, String>{};

  static Future<LocalKeyValueStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalKeyValueStore._(preferences);
  }

  String? read(String key) => _preferences?.getString(key) ?? _memory[key];

  void write(String key, String value) {
    _memory[key] = value;
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.setString(key, value));
    }
  }

  void delete(String key) {
    _memory.remove(key);
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.remove(key));
    }
  }
}
