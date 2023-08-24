import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:vdsinamonitor/globals/typedefs.dart';

// var aaa = await tryExtractAsset('/sqlite/sqlite3.dll');
Future<ByteData?> tryExtractAsset(final String assetPath) async {
  final encoded =
      utf8.encoder.convert(Uri(path: Uri.encodeFull('assets$assetPath')).path);
  return await ServicesBinding.instance.defaultBinaryMessenger
      .send('flutter/assets', encoded.buffer.asByteData());
}

TResultEx resultEx(bool result,
    {ResultCode? code, String? message, String? userMessage}) {
  return (
    result: result,
    details: [code, message, userMessage].any((el) => el != null)
        ? (code: code, message: message, userMessage: userMessage)
        : null
  );
}
