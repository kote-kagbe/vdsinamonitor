import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:ffi';

import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:path/path.dart';

import 'package:vdsinamonitor/bl/db.dart';
import 'package:vdsinamonitor/bl/sqlite/database.dart';
import 'package:vdsinamonitor/globals/utils.dart';

Future<bool> initialize() async {
  return await Future<bool>(() async {
    bool result = true;

    dataFolder = (await getApplicationSupportDirectory()).path;

    if(Platform.isWindows) {
      String lib = path.join(dataFolder, 'sqlite3.dll');
      var data = await tryExtractAsset('assets/sql/sqlite3.dll');
      if(data != null) {
        var list = data.buffer.asUint8List();
        await File(lib).writeAsBytes(list);
      } else {
        result = false;
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