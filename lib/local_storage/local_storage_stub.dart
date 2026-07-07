class LocalKeyValueStore {
  final Map<String, String> _memory = <String, String>{};

  static Future<LocalKeyValueStore> create() async => LocalKeyValueStore();

  String? read(String key) => _memory[key];

  void write(String key, String value) {
    _memory[key] = value;
  }

  void delete(String key) {
    _memory.remove(key);
  }

  /// 内存实现无异步落盘，无需等待。
  Future<void> flush() async {}
}
