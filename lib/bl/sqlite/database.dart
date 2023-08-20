import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite3/open.dart' as sqlite_open;

import 'package:vdsinamonitor/globals/typedefs.dart';
import 'package:vdsinamonitor/bl/sqlite/converter.dart';
import 'package:vdsinamonitor/globals/utils.dart';

typedef OSOverride = ({
  sqlite_open.OperatingSystem os,
  DynamicLibrary Function() overrideFunc
});

typedef TransactionMethod<T> = Future<T> Function();
typedef TransactionBlock<T> = ({Completer<T> completer, TransactionMethod<T> method, String transactionType});

class SQLiteDatabase {
  sqlite3.Database? _db;
  String? _path;
  final String _name;
  final bool _convert;
  final bool _reset;
  final List<OSOverride>? _overrides;
  final Queue<TransactionBlock> _transactionQueue = Queue<TransactionBlock>();

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

  Future<TResultEx> openEx() async {
    return await Future<TResultEx>(() async {
      try {
        if (_name.isEmpty) {
          return resultEx(
            false,
            code: ResultCode.rcError,
            message: 'DB name is not specified'
          );
        }

        if (_path != null) {
          if (_path!.isEmpty) {
            _path = (await getApplicationSupportDirectory()).path;
          }
          bool exists = await Directory(_path!).exists();
          if (!exists) {
            return resultEx(
              false,
              code: ResultCode.rcError,
              message: 'DB folder doesn''t exist'
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

        _db?.execute('PRAGMA foreign_keys = ON;');

        return resultEx(true);
      } catch (e) {
        return resultEx(
          false,
          code: ResultCode.rcError,
          message: e.toString()
        );
      }
    });
  }

  TResultEx _attachDB() {
    if (_path == null) {
      _db = sqlite3.sqlite3.openInMemory();
    } else {
      if (_name.isEmpty) {
        return resultEx(
          false,
          code: ResultCode.rcError,
          message: 'DB path is set but DB name is not specified'
        );
      }
      _db = sqlite3.sqlite3.open(path.join(_path!, _name));
    }
    return resultEx(true);
  }

  Future<bool> open() async {
    var result = await openEx();
    return result.result;
  }

  void close() {
    _db?.dispose();
    _db = null;
  }

  Future<TResultEx> resetEx({bool convert = true}) async {
    return await Future<TResultEx>(() async {
      if (_db != null) {
        close();
      }
      if (_path != null) {
        try {
          File(path.join(_path!, _name)).deleteSync();
        } catch (e) {
          return resultEx(
            false,
            code: ResultCode.rcError,
            message: e.toString()
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
      return resultEx(true);
    });
  }

  Future<bool> reset({bool convert = true}) async {
    return await Future<bool>(() async {
      var result = await resetEx(convert: convert);
      return result.result;
    });
  }

  Future<TResultEx> convertEx() async {
    try {
      final cnvResult = await SQLiteDatabaseConverter(_db!, _name).execute();
      return resultEx((cnvResult.version ?? 0) > 0);
    } catch (e) {
      return resultEx(false);
    }
  }

  Future<bool> convert() async {
    return await Future<bool>(() async {
      var result = await convertEx();
      return result.result;
    });
  }

  void execute(String query, [List<Object?> params = const []]) {
    _db?.execute(query, params);
  }

  sqlite3.ResultSet? select(String query, [List<Object?> params = const []]) {
    return _db?.select(query, params);
  }

  sqlite3.Row? selectRow(String query, [List<Object?> params = const []]) {
    final rs = select(query, params);
    if(rs != null && rs.isNotEmpty) {
      return rs[0];
    }
    return null;
  }

  T? selectScalar<T>(String query, [List<Object?> params = const []]) {
    final row = selectRow(query, params);
    if(row != null && row.isNotEmpty) {
      return row[0] as T;
    }
    return null;
  }

  Future<T> withTransaction<T>({required TransactionMethod<T> method, String transactionType = 'DEFERRED'}) {
    const transactionTypes = <String>['DEFERRED', 'IMMEDIATE', 'EXCLUSIVE '];
    if(!transactionTypes.any((element) => element == transactionType.toUpperCase())) {
      throw Exception('Транзакция должна иметь один из этих типов: ${transactionTypes.join(', ')}');
    }
    final Completer<T> completer = Completer<T>();
    _transactionQueue.addLast((completer: completer, method: method, transactionType: transactionType));
    if(_transactionQueue.length == 1) {
      _processTransactionQueue<T>();
    }
    return completer.future;
  }

  void _processTransactionQueue<T>() {
    if(_transactionQueue.isNotEmpty) {
      final item = _transactionQueue.first;
      if(_db != null) {
        Future<void>(() {
          _db?.execute('begin ${item.transactionType} transaction');
        }).then((_) {
          item.method()
            .then((methodResult) {
              _db?.execute('commit transaction');
              item.completer.complete(methodResult);
              _transactionQueue.removeFirst();
              _processTransactionQueue();
            })
            .catchError((methodError) {
              _db?.execute('rollback transaction');
              item.completer.completeError(methodError);
              _transactionQueue.removeFirst();
              _processTransactionQueue();
            });
        }).catchError((e) {
          item.completer.completeError('Не удалось создать транзакцию: $e');
          _transactionQueue.removeFirst();
          _processTransactionQueue();
        });
      } else {
        item.completer.completeError('База данных не подключена');
        _transactionQueue.removeFirst();
        _processTransactionQueue();
      }
    }
  }
}
