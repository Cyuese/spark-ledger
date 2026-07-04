import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web 使用 sqflite_common_ffi_web（依赖 web/sqlite3.wasm 与 web/sqflite_sw.js）。
Future<DatabaseFactory> resolveDatabaseFactory() async => databaseFactoryFfiWeb;

/// Web 侧数据库以名称作为标识，持久化在 IndexedDB。
Future<String> resolveDatabasePath(String name) async => name;
