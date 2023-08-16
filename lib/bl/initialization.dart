import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:ffi';
import 'dart:async';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:path/path.dart';

import 'package:vdsinamonitor/bl/db.dart';
import 'package:vdsinamonitor/bl/sqlite/database.dart';
import 'package:vdsinamonitor/globals/utils.dart';
import 'package:vdsinamonitor/globals/typedefs.dart';

void initialize(Completer completer) async {
  dataFolder = (await getApplicationSupportDirectory()).path;
  tempFolder = (await getTemporaryDirectory()).path;

  if (Platform.isWindows) {
    String lib = path.join(dataFolder, 'sqlite3.dll');
    var data = await tryExtractAsset('/sqlite/sqlite3.dll');
    if (data != null) {
      var list = data.buffer.asUint8List();
      await File(lib).writeAsBytes(list);
    } else {
      completer.complete((result: false, details: null));
      return;
    }
  }

  db = SQLiteDatabase(
    overrides: <OSOverride>[
      (os: sqlite_open.OperatingSystem.windows, overrideFunc: _windowsOverride),
    ],
    path: null,
    name: 'vdsinamonitor.db',
  );
  if (!(await db.openEx()).result) {
    completer.complete((result: false, details: null));
    return;
  }

  completer.complete((result: true, details: null));
}

DynamicLibrary _windowsOverride() {
  final sqliteLib = File(join(dataFolder, 'sqlite3.dll'));
  return DynamicLibrary.open(sqliteLib.path);
}
