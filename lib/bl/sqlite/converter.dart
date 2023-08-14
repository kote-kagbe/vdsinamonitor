import 'package:sqlite3/sqlite3.dart';

import 'package:vdsinamonitor/globals/typedefs.dart';

typedef DBVersion = ({int? version, int? subversion});

const dbVersionKey = 'version';
const dbSubVersionKey = 'sub_version';
const dbInfoTable = 'db_info';

class SQLiteDatabaseConverter {
  final Database _db;
  int _version = 0, _subVersion = 0;

  SQLiteDatabaseConverter(this._db);

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
    await Future.delayed(const Duration(seconds: 1));
    return (version: _version, subversion: _subVersion);
  }
}
