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

ImageProvider imageProviderForSource(String source) {
  final bytes = bytesFromDataUrl(source);
  if (bytes != null) {
    return MemoryImage(bytes);
  }
  return NetworkImage(source);
}

Widget imageForSource(
  String source, {
  BoxFit fit = BoxFit.cover,
  AlignmentGeometry alignment = Alignment.center,
}) {
  final bytes = bytesFromDataUrl(source);
  if (bytes != null) {
    return Image.memory(
      bytes,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
    );
  }
  return Image.network(source, fit: fit, alignment: alignment);
}
