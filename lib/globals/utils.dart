import 'dart:convert';
import 'package:flutter/services.dart';

// var aaa = await tryExtractAsset('assets/sql/sqlite3.dll');
Future<ByteData?> tryExtractAsset(final String assetPath) async {
  final encoded = utf8.encoder.convert(Uri(path: Uri.encodeFull(assetPath)).path);
  return await ServicesBinding.instance.defaultBinaryMessenger.send('flutter/assets', encoded.buffer.asByteData());
}