import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

// var aaa = await tryExtractAsset('/sqlite/sqlite3.dll');
Future<ByteData?> tryExtractAsset(final String assetPath) async {
  final encoded =
      utf8.encoder.convert(Uri(path: Uri.encodeFull('assets$assetPath')).path);
  return await ServicesBinding.instance.defaultBinaryMessenger
      .send('flutter/assets', encoded.buffer.asByteData());
}
