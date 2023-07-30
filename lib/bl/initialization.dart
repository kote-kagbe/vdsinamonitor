import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ffi';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:path/path.dart';

import 'package:vdsinamonitor/bl/db.dart';
import 'package:vdsinamonitor/bl/sqlite/database.dart';

Future<bool> initialize() async {
  return await Future<bool>(() async {
    bool result = true;

    dataFolder = (await getApplicationSupportDirectory()).path;

    bool dbReady = true;
    if(Platform.isWindows) {
      String lib = path.join(dataFolder, 'sqlite3.dll');
      bool exists = await File(lib).exists();
      if(!exists) {
        var data = await rootBundle.load("assets/sql/sqlite3.dll");
        var list = data.buffer.asUint8List();
        await File(lib).writeAsBytes(list);
      }
    }

    db = SQLiteDatabase(overrides: <OSOverride>[(os: sqlite_open.OperatingSystem.windows, overrideFunc: _windowsOverride),]);
    var dbOpenRes = await db.openEx();
    result = result && dbOpenRes.result;

    return result;
  });
}

DynamicLibrary _windowsOverride() {
  final sqliteLib = File(join(dataFolder, 'sqlite3.dll'));
  return DynamicLibrary.open(sqliteLib.path);
}