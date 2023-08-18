import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vdsinamonitor/bl/db.dart';

import 'package:vdsinamonitor/globals/typedefs.dart';
import 'package:vdsinamonitor/globals/utils.dart';

typedef DBVersion = ({int? version, int? subversion});

const dbVersionKey = 'version';
const dbSubVersionKey = 'sub_version';
const dbInfoTable = 'db_info';

class SQLiteDatabaseConverter {
  final Database _db;
  final String _dbName;
  int _version = 0, _subVersion = 0;
  final _executed = <String>{};

  SQLiteDatabaseConverter(this._db, this._dbName);

  void _prepare() {
    final test = _db.select('''
      select 1 from [sqlite_master] where [name] = '$dbInfoTable' and [type] = 'table'
    ''');
    if (test.isNotEmpty) {
      _getVersion();
    } else {
      _initDB();
    }
  }

  void _initDB() {
    _db.execute('''
      create table [$dbInfoTable] (
        [id] integer not null primary key,
        [key] text not null,
        [value] text
      ) strict;
    ''');
    _db.execute('''
      create unique index [ui_db_info_key] on [$dbInfoTable]([key]);
    ''');
    _db.execute('''
      insert into [$dbInfoTable] ([key]) values ('$dbVersionKey'), ('$dbSubVersionKey');
    ''');
  }

  void _getVersion() {
    final version = _db.select('''
      select 
        (select cast([value] as integer) from [$dbInfoTable] where [key] = '$dbVersionKey') [$dbVersionKey]
        , (select cast([value] as integer) from [$dbInfoTable] where [key] = '$dbSubVersionKey') [$dbSubVersionKey]
    ''');
    if (version.isNotEmpty) {
      _version = version[0][dbVersionKey] ?? 0;
      _subVersion = version[0][dbSubVersionKey] ?? 0;
    }
  }

  Future<DBVersion> execute() async {
    _prepare();

    ByteData? code;
    do {
      String subConverter = '/sqlite/$_dbName.$_version.$_subVersion.sql';
      if (_executed.contains(subConverter)) {
        throw Exception('Зацикливание конвертации на конвертере $subConverter');
      }
      code = await tryExtractAsset(subConverter);
      if (code != null) {
        await _applyConverter(code);
        _executed.add(subConverter);
      } else {
        String converter = '/sqlite/$_dbName.$_version.sql';
        if (_executed.contains(converter)) {
          throw Exception('Зацикливание конвертации на конвертере $converter');
        }
        code = await tryExtractAsset(converter);
        if (code != null) {
          await _applyConverter(code);
          _executed.add(converter);
        }
      }
    } while (code != null);

    return (version: _version, subversion: _subVersion);
  }

  Future<void> _applyConverter(ByteData code) async {
    final Completer<void> completer = Completer();

    final codeFile = File(path.join(tempFolder, _dbName));
    // await codeFile.writeAsBytes(
    //     code.buffer.asInt8List(code.offsetInBytes, code.lengthInBytes));
    // final lines = await codeFile.readAsLines();
    // codeFile.delete();
    // for (final line in lines) {
    //   final s = line;
    // }

    // Stream<List<int>> codeStream = codeFile.openRead();
    try {
      // final Stream<int> codeStream =
      //     Stream.fromIterable(code.buffer.asUint8List());
      // codeStream
      //     .transform(StreamTransformer.fromHandlers(
      //         handleData: (int data, EventSink<List<int>> sink) =>
      //             sink.add(<int>[data])))
      final sink = codeFile.openWrite();

      partGenerator(code.buffer.asUint8List())
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        sink.writeln(line);
      }, onDone: () {
        sink.close();
        completer.complete();
      });
    } catch (e) {
      final s = '$e';
    }

    // completer.complete();

    // if (Platform.isWindows) {
    //   // под виндой не работает transform(utf8.decoder), ругается на кириллицу
    //   // а вот читает из файла без ошибок, зараза
    //   final codeFile = File(path.join(tempFolder, _dbName));
    //   await codeFile.writeAsBytes(
    //       code.buffer.asInt8List(code.offsetInBytes, code.lengthInBytes));
    //   final lines = await codeFile.readAsLines();
    //   for (final line in lines) {
    //     final s = line;
    //   }
    //   codeFile.delete();
    //   completer.complete();
    // } else {
    //   final Stream<List<int>> codeStream = Stream.fromIterable(
    //       [code.buffer.asInt8List(code.offsetInBytes, code.lengthInBytes)]);
    //   codeStream.transform(utf8.decoder).transform(const LineSplitter()).listen(
    //       (String line) {
    //     final s = line;
    //     assert(s.isNotEmpty);
    //   }, onDone: () => completer.complete());
    // }

    return completer.future;
  }

  void _setVersion({int? version, int? subVersion}) {
    if (version != null) {
      _db.execute('''
        insert into [$dbInfoTable] ([key], [value]) values ($dbVersionKey, $version)
        on conflict [key] do update set [value] = excluded.value
      ''');
      _version = version;
    }
    if (subVersion != null) {
      _db.execute('''
        insert into [$dbInfoTable] ([key], [value]) values ($dbSubVersionKey, $subVersion)
        on conflict [key] do update set [value] = excluded.value
      ''');
      _subVersion = subVersion;
    }
  }
}

Stream<List<int>> partGenerator(Uint8List list) async* {
  var offset = 0;
  const partSize = 100;
  while (offset < list.length) {
    yield list.sublist(offset, min(list.length, offset + partSize));
    offset += partSize;
  }
}
