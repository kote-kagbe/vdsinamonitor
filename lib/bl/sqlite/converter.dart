import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

import 'package:sqlite3/sqlite3.dart';

import 'package:vdsinamonitor/globals/typedefs.dart';
import 'package:vdsinamonitor/globals/utils.dart';

typedef DBVersion = ({int? version, int? subversion});
typedef QueryParams = ({Map<String, String>? extract, List<String>? apply});

const dbVersionKey = 'version';
const dbSubVersionKey = 'sub_version';
const dbInfoTable = 'db_info';

class SQLiteDatabaseConverter {
  final Database _db;
  final String _dbName;
  int _version = 0, _subVersion = 0;

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
    final executed = <String>{};
    do {
      String subConverter = '/sqlite/$_dbName.$_version.$_subVersion.sql';
      if (executed.contains(subConverter)) {
        throw Exception('Зацикливание конвертации на конвертере $subConverter');
      }
      code = await tryExtractAsset(subConverter);
      if (code != null) {
        await _applyConverter(code);
        executed.add(subConverter);
      } else {
        String converter = '/sqlite/$_dbName.$_version.sql';
        if (executed.contains(converter)) {
          throw Exception('Зацикливание конвертации на конвертере $converter');
        }
        code = await tryExtractAsset(converter);
        if (code != null) {
          await _applyConverter(code);
          executed.add(converter);
        }
      }
    } while (code != null);

    return (version: _version, subversion: _subVersion);
  }

  Future<ResultEx> _applyConverter(ByteData code) async {
    final Completer<ResultEx> completer = Completer();

    int counter = 1;
    final List<String> request = [];
    final Map<String, dynamic> paramList = {};
    QueryParams? params;

    try {
      _db.execute('begin exclusive transaction');

      _parseCode(code.buffer.asUint8List())
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
          if(line.startsWith('@') && request.isEmpty) {
            _processMacros(line.substring(1), counter);
            counter += 1;
          } else if(line.startsWith(r'$') && request.isEmpty) {
            params = _processParams(paramList, line.substring(1), counter, params);
            counter += 1;
          } else if(line.isEmpty && request.isNotEmpty) {
            String query = request.join('\n');
            if(params == null) {
              _db.execute(query);
            } else {
              List<dynamic> args = [...(paramList.entries.where((el) => (params?.apply ?? []).contains(el.key))).map((el) => el.value)];
              Map<String, String>? param = params?.extract;
              if(param != null) {
                final result = _db.select(query, args);
                for(final pair in param.entries) {
                  paramList[pair.key] = result.isNotEmpty ? result[0][pair.value] : null;
                }
              } else {
                _db.execute(query, args);
              }
            }
            request.clear();
            params = null;
            counter += 1;
          } else {
            if(line.trim().isNotEmpty) {
              request.add(line);
            }
          }
      }, onDone: () {
        if(request.isNotEmpty) {
          _db.execute(request.join('\n'), [...(paramList.entries.where((el) => (params?.apply ?? []).contains(el.key))).map((el) => el.value)]);
        }
        _db.execute('commit transaction');
        completer.complete((result: true, details: null));
      });
      
    } catch (e) {
      _db.execute('rollback transaction');
      throw Exception('Ошибка применения конвертера: $e');
    }

    return completer.future;
  }

  QueryParams _processParams(Map<String, dynamic> paramList, String macros, int counter, QueryParams? update) {
    List<String> parts = macros.split(' ');
    if(parts.length < 2) {
      throw Exception('Неверный синтаксис макроса $macros #$counter');
    }
    switch (parts[0]) {
      case '<': {
        final Map<String, String> extract = {};
        for(final param in parts.sublist(1)) {
          final List<String> data = param.split(':');
          extract[data[0]] = data.length > 1 ? data[1] : data[0];
        }
        return (extract: extract, apply: update?.apply);
      }
      case '>': {
        parts.sublist(1).forEach((el) {
          if(!paramList.containsKey(el)) {
            throw Exception('Не найден параметр $el макроса $macros #$counter');
          }
        });
        return (apply: parts.sublist(1), extract: update?.extract);
      }
      default: throw Exception('Неизвестный макрос $macros #$counter');
    }
  }

  void _processMacros(String macros, int counter) {
    final List<String> parts = macros.split(' ');
    if(parts.isEmpty) {
      throw Exception('Пустое тело макроса $macros');
    }
    switch (parts[0]) {
      case 'set': {
        if(parts.length != 3) {
          throw Exception('Неверное количество аргументов для макроса $macros #$counter');
        }
        int? value = int.tryParse(parts[2]);
        if(value == null) {
          throw Exception('Неверное значение аргумента ${parts[2]} макроса $macros #$counter');
        }
        switch (parts[1]) {
          case 'version': _setVersion(version: value);
          case 'subversion': _setVersion(subVersion: value);
          default: throw Exception('Неверное значение аргумента ${parts[1]} макроса $macros #$counter');
        }
      }
      default:
        throw Exception('Неизвестный макрос $macros #$counter');
    }
  }

  Stream<List<int>> _parseCode(Uint8List list) async* {
    var offset = 0;
    const partSize = 1024;
    while (offset < list.length) {
      yield list.sublist(offset, min(list.length, offset + partSize));
      offset += partSize;
    }
  }

  void _setVersion({int? version, int? subVersion}) {
    if (version != null) {
      _db.execute('''
        insert into [$dbInfoTable] ([key], [value]) values (?1, ?2)
        on conflict ([key]) do update set [value] = excluded.value
      ''', [dbVersionKey, version]);
      _version = version;
    }
    if (subVersion != null) {
      _db.execute('''
        insert into [$dbInfoTable] ([key], [value]) values (?1, ?2)
        on conflict ([key]) do update set [value] = excluded.value
      ''', [dbSubVersionKey, subVersion]);
      _subVersion = subVersion;
    }
  }
}
