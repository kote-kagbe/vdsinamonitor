import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum LogType {
  ltINFO('INFO'),
  ltWARNING('WARNING'),
  ltERROR('ERROR'),
  ltFATAL('FATAL');

  const LogType(this.text);
  final String text;
}

typedef LogInfo = ({
  String message,
  LogType type,
  DateTime dt,
  Completer? completer
});

class Logger {
  static final Logger _logger = Logger._spawn(StreamController<LogInfo>());

  String? _tmpPath;
  String? _docsPath;
  late final String _name;
  final StreamController<LogInfo> _logChannel;
  late final StreamSubscription<LogInfo> _logSubscription;
  IOSink? _logSink;
  static bool? _initialized = false;

  factory Logger(String name) {
    if (_initialized != null) {
      if (!_initialized!) {
        _initialized = true;
        _logger._name = name;
        getTemporaryDirectory().then((directory) {
          _logger
            .._tmpPath = path.join(directory.path, '${_logger._name}.log')
            .._logSink = File(_logger._tmpPath!).openWrite()
            .._logSubscription.resume();
        });
      }
      return Logger._logger;
    } else {
      throw Exception('Логгер был остановлен');
    }
  }

  Logger._spawn(this._logChannel) {
    _logSubscription = _logChannel.stream.listen(_write);
    _logSubscription.pause();
  }

  void dispose() {
    _logSubscription.cancel();
    _logSink?.close();
    _logChannel.close();
    _initialized = null;
  }

  void _write(LogInfo info) {
    _logSink?.writeln('${info.dt} [${info.type.text}] ${info.message}');
    info.completer?.complete();
  }

  void _log(String message, LogType type, {Completer? completer}) async {
    _logChannel.add((
      message: message,
      type: type,
      dt: DateTime.now(),
      completer: completer
    ));
  }

  Future<void> export() async {
    if (_tmpPath != null) {
      _docsPath ??= path.join(
          (await getApplicationDocumentsDirectory()).path, '$_name.log');
      if (_docsPath != null && _docsPath!.isNotEmpty) {
        _logSubscription.pause();
        _logSink?.close();
        _logSink = null;
        await File(_tmpPath!).copy(_docsPath!);
        _logSink = File(path.join(_tmpPath!)).openWrite(mode: FileMode.append);
        _logSubscription.resume();
      }
    }
  }

  void info(String message) {
    _log(message, LogType.ltINFO);
  }

  void warning(String message) {
    _log(message, LogType.ltWARNING);
  }

  void error(String message) {
    _log(message, LogType.ltERROR);
  }

  Future<void> fatal(String message) {
    Completer completer = Completer();
    _log(message, LogType.ltFATAL, completer: completer);
    return completer.future;
  }
}
