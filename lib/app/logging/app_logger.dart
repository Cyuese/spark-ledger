import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../local_storage/local_storage.dart';

/// 软件日志级别。
enum AppLogLevel {
  info,
  warning,
  error;

  String get storageValue => name;

  static AppLogLevel fromStorage(String? value) {
    return AppLogLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => AppLogLevel.info,
    );
  }
}

/// 一条软件日志记录：时间、级别、来源、消息。
@immutable
class AppLogRecord {
  const AppLogRecord({
    required this.time,
    required this.level,
    required this.message,
    this.source,
  });

  final DateTime time;
  final AppLogLevel level;
  final String message;
  final String? source;

  Map<String, Object?> toJson() => <String, Object?>{
    'time': time.toIso8601String(),
    'level': level.storageValue,
    'message': message,
    if (source != null && source!.isNotEmpty) 'source': source,
  };

  static AppLogRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final time = DateTime.tryParse(raw['time'] as String? ?? '');
    final message = raw['message'] as String?;
    if (time == null || message == null) return null;
    return AppLogRecord(
      time: time,
      level: AppLogLevel.fromStorage(raw['level'] as String?),
      message: message,
      source: raw['source'] as String?,
    );
  }
}

/// 应用内轻量日志：记录错误与关键事件到环形缓冲（最近 [_maxRecords] 条），
/// 持久化到 KV（设备本地、不进 JSON 备份），供「软件日志」页查看/复制/分享，
/// 方便用户反馈问题时提供诊断线索。
class AppLogger extends ChangeNotifier {
  AppLogger(this._store) {
    _load();
  }

  static const String _storageKey = 'verifin.logs.v1';
  static const int _maxRecords = 200;

  final LocalKeyValueStore _store;

  /// 最新在前。
  final List<AppLogRecord> _records = <AppLogRecord>[];

  /// 只读视图，最新记录在前。
  List<AppLogRecord> get records =>
      UnmodifiableListView<AppLogRecord>(_records);

  bool get isEmpty => _records.isEmpty;

  void info(String message, {String? source}) =>
      log(AppLogLevel.info, message, source: source);

  void warning(String message, {String? source}) =>
      log(AppLogLevel.warning, message, source: source);

  /// 记录一条错误；可附带原始异常对象（会拼接到消息末尾）。
  void error(String message, {String? source, Object? error}) {
    final text = error == null ? message : '$message: $error';
    log(AppLogLevel.error, text, source: source);
  }

  void log(AppLogLevel level, String message, {String? source}) {
    _records.insert(
      0,
      AppLogRecord(
        time: DateTime.now(),
        level: level,
        message: message,
        source: source,
      ),
    );
    if (_records.length > _maxRecords) {
      _records.removeRange(_maxRecords, _records.length);
    }
    _persist();
    notifyListeners();
  }

  void clear() {
    if (_records.isEmpty) return;
    _records.clear();
    _persist();
    notifyListeners();
  }

  /// 导出为可复制/分享的纯文本，最新在前。
  String exportText() {
    return _records
        .map((r) {
          final ts = r.time.toIso8601String();
          final src = (r.source == null || r.source!.isEmpty)
              ? ''
              : ' [${r.source}]';
          return '$ts ${r.level.name.toUpperCase()}$src ${r.message}';
        })
        .join('\n');
  }

  void _load() {
    final raw = _store.read(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final item in decoded) {
        final record = AppLogRecord.fromJson(item);
        if (record != null) _records.add(record);
      }
      if (_records.length > _maxRecords) {
        _records.removeRange(_maxRecords, _records.length);
      }
    } catch (_) {
      _store.delete(_storageKey);
    }
  }

  void _persist() {
    _store.write(
      _storageKey,
      jsonEncode(_records.map((r) => r.toJson()).toList()),
    );
  }
}
