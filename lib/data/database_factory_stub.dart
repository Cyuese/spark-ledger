import 'package:sqflite_common/sqlite_api.dart';

/// stub 平台不提供数据库实现；测试用例应显式注入 ffi factory 与内存路径。
Future<DatabaseFactory> resolveDatabaseFactory() async {
  throw UnsupportedError('当前平台未提供 SQLite 实现');
}

Future<String> resolveDatabasePath(String name) async => name;
