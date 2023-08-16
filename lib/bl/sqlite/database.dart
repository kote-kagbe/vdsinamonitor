import 'dart:ffi';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite3/open.dart' as sqlite_open;

import 'package:vdsinamonitor/globals/typedefs.dart';
import 'package:vdsinamonitor/bl/sqlite/converter.dart';

typedef OSOverride = ({
  sqlite_open.OperatingSystem os,
  DynamicLibrary Function() overrideFunc
});

class SQLiteDatabase {
  sqlite3.Database? _db;
  String? _path;
  final String _name;
  final bool _convert;
  final bool _reset;
  final List<OSOverride>? _overrides;

  SQLiteDatabase({
    String? path = '',
    String name = 'db.sqlite',
    bool convert = true,
    bool reset = false,
    List<OSOverride>? overrides,
  })  : _path = path,
        _name = name,
        _convert = convert,
        _reset = reset,
        _overrides = overrides;

  Future<ResultEx> openEx() async {
    return await Future<ResultEx>(() async {
      try {
        if (_name.isEmpty) {
          return (
            result: false,
            details: (
              code: ResultCode.rcError,
              message: 'DB name is not specified'
            )
          );
        }

        if (_path != null) {
          if (_path!.isEmpty) {
            _path = (await getApplicationSupportDirectory()).path;
          }
          bool exists = await Directory(_path!).exists();
          if (!exists) {
            return (
              result: false,
              details: (
                code: ResultCode.rcError,
                message: 'DB folder doesn' 't exist'
              )
            );
          }
        }

        if (_overrides != null) {
          for (var override in _overrides!) {
            sqlite_open.open.overrideFor(override.os, override.overrideFunc);
          }
        }

        if (_reset) {
          var resetRes = await resetEx(convert: _convert);
          if (!resetRes.result) {
            return resetRes;
          }
        }

        final attachResult = _attachDB();
        if (!attachResult.result) {
          return attachResult;
        }

        if (_convert && !_reset) {
          var cnvRes = await convertEx();
          if (!cnvRes.result) {
            return cnvRes;
          }
        }

        return (result: true, details: null);
      } catch (e) {
        return (
          result: false,
          details: (code: ResultCode.rcError, message: e.toString())
        );
      }
    });
  }

  ResultEx _attachDB() {
    if (_path == null) {
      _db = sqlite3.sqlite3.openInMemory();
    } else {
      if (_name.isEmpty) {
        return (
          result: false,
          details: (
            code: ResultCode.rcError,
            message: 'DB path is set but DB name is not specified'
          )
        );
      }
      _db = sqlite3.sqlite3.open(path.join(_path!, _name));
    }
    return (result: true, details: null);
  }

  Future<bool> open() async {
    var result = await openEx();
    return result.result;
  }

  void close() {
    _db?.dispose();
    _db = null;
  }

  Future<ResultEx> resetEx({bool convert = true}) async {
    return await Future<ResultEx>(() async {
      if (_db != null) {
        close();
      }
      if (_path != null) {
        try {
          File(path.join(_path!, _name)).deleteSync();
        } catch (e) {
          return (
            result: false,
            details: (code: ResultCode.rcError, message: e.toString())
          );
        }
      }
      _attachDB();
      if (convert) {
        var cnvRes = await convertEx();
        if (!cnvRes.result) {
          return cnvRes;
        }
      }
      return (result: true, details: null);
    });
  }

  Future<bool> reset({bool convert = true}) async {
    return await Future<bool>(() async {
      var result = await resetEx(convert: convert);
      return result.result;
    });
  }

  Future<ResultEx> convertEx() async {
    try {
      final cnvResult = await SQLiteDatabaseConverter(_db!, _name).execute();
      return (result: (cnvResult.version ?? 0) > 0, details: null);
    } catch (e) {
      return (result: false, details: null);
    }
  }

  Future<bool> convert() async {
    return await Future<bool>(() async {
      var result = await convertEx();
      return result.result;
    });
  }
}
