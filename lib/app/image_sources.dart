import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

Uint8List? bytesFromDataUrl(String source) {
  if (!source.startsWith('data:')) {
    return null;
  }
  final commaIndex = source.indexOf(',');
  if (commaIndex == -1) {
    return null;
  }
  try {
    return base64Decode(source.substring(commaIndex + 1));
  } on FormatException {
    return null;
  }
}

// data URL 每次 build 重新 base64 解码会得到新的字节数组,MemoryImage 按
// 字节对象身份判等,会被当成"新图片"重新解码,期间画面短暂空白造成闪烁。
// 用小容量 LRU 复用 provider,让 Flutter 图片缓存稳定命中(头像 + 资产背景)。
const int _maxCachedDataUrlProviders = 4;
final Map<String, MemoryImage> _dataUrlProviderCache = <String, MemoryImage>{};

ImageProvider imageProviderForSource(String source) {
  final cached = _dataUrlProviderCache.remove(source);
  if (cached != null) {
    _dataUrlProviderCache[source] = cached;
    return cached;
  }
  final bytes = bytesFromDataUrl(source);
  if (bytes == null) {
    // NetworkImage 按 url 判等,本身不会闪烁,无需缓存。
    return NetworkImage(source);
  }
  final provider = MemoryImage(bytes);
  _dataUrlProviderCache[source] = provider;
  if (_dataUrlProviderCache.length > _maxCachedDataUrlProviders) {
    _dataUrlProviderCache.remove(_dataUrlProviderCache.keys.first);
  }
  return provider;
}

Widget imageForSource(
  String source, {
  BoxFit fit = BoxFit.cover,
  AlignmentGeometry alignment = Alignment.center,
}) {
  return Image(
    image: imageProviderForSource(source),
    fit: fit,
    alignment: alignment,
    gaplessPlayback: true,
  );
}
