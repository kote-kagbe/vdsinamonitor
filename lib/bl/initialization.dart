import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:ffi';
import 'dart:async';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:path/path.dart';

import 'package:vdsinamonitor/bl/db.dart';
import 'package:vdsinamonitor/bl/sqlite/database.dart';
import 'package:vdsinamonitor/globals/intercom.dart';
import 'package:vdsinamonitor/globals/utils.dart';
import 'package:vdsinamonitor/globals/consts/strings.dart';

void initialize(Completer completer) async {
  final log = logger.custom('Инициализация');

  log.info('получение служебных директорий');
  dataFolder = (await getApplicationSupportDirectory()).path;
  log.info('папка данных: $dataFolder');
  tempFolder = (await getTemporaryDirectory()).path;
  log.info('папка временных файлов: $tempFolder');

  if (Platform.isWindows) {
    log.info('тебуется копирование sqlite3.dll');
    String lib = path.join(dataFolder, 'sqlite3.dll');
    log.info('путь $lib');
    log.info('извлекаем asset');
    var data = await tryExtractAsset('/sqlite/sqlite3.dll');
    if (data != null) {
      log.info('записываем в файл');
      var list = data.buffer.asUint8List();
      await File(lib).writeAsBytes(list);
    } else {
      log.error('ошибка записи в файл');
      completer.completeError(resultEx(false));
      return;
    }
  }

  log.info('запуск инициализации конфигурации');
  await config.initialize();

  log.info('подключение БД');
  db = SQLiteDatabase(
    overrides: <OSOverride>[
      (
        os: sqlite_open.OperatingSystem.windows,
        overrideFunc: () {
          final sqliteLib = File(join(dataFolder, 'sqlite3.dll'));
          return DynamicLibrary.open(sqliteLib.path);
        }
      ),
    ],
    path: null,
    name: '$applicationTitleMerged.db',
  );
  if (!(await db.openEx()).result) {
    log.error('не удалось подключить БД');
    completer.completeError(resultEx(false));
    return;
  }

  log.info('инициализация завершена');
  completer.complete(resultEx(true));
}
