import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalKeyValueStore {
  /// 仅供测试：不接 SharedPreferences 的纯内存实现，进程重启即丢。
  /// **真实平台一律用 [create]**——误用此构造会静默丢失全部偏好。
  @visibleForTesting
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
