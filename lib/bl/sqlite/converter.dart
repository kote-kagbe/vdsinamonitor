import 'package:sqlite3/sqlite3.dart';

import 'package:vdsinamonitor/globals/typedefs.dart';

typedef DBVersion = ({int? version, int? subversion});

const dbVersionKey = 'version';
const dbSubVersionKey = 'sub_version';

class SQLiteDatabaseConverter {
  final Database _db;
  int? _version,
      _subVersion;

  SQLiteDatabaseConverter(this._db);

  void _prepare() {
    final test = _db.select('''
      select 1 from [sqlite_master] where [name] = 'db_info' and [type] = 'table'
    ''');
    if(test.isNotEmpty) {
      _getVersion();
    } else {
      _initDB();
    }
  }

  void _initDB() {
    _db.execute('''
      create table [db_info] (
        [id] integer not null primary key,
        [key] text not null,
        [value] text
      ) strict;
    ''');
    _db.execute('''
      create unique index [ui_db_info_key] on [db_info]([key]);
    ''');
    _db.execute('''
      insert into [db_info] ([key]) values ('$dbVersionKey', '$dbSubVersionKey');
    ''');
  }

  void _getVersion() {
    final version = _db.select('''
      select 
        (select [value] from [db_info] where [key] = '$dbVersionKey') [version]
        , (select [value] from [db_info] where [key] = '$dbSubVersionKey') [sub_version]
    ''');
    if(version.isNotEmpty) {
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