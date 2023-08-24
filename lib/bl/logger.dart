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

abstract class AbstractLogger {
  void info(String message);

  void warning(String message);

  void error(String message);

  Future<void> fatal(String message);
}

class CustomLogger implements AbstractLogger {
  final String _prefix;
  final AbstractLogger _parent;

  CustomLogger(this._prefix, this._parent);

  @override
  void info(String message) {
    _parent.info('[$_prefix] $message');
  }

  @override
  void warning(String message) {
    _parent.warning('[$_prefix] $message');
  }

  @override
  void error(String message) {
    _parent.error('[$_prefix] $message');
  }

  @override
  Future<void> fatal(String message) {
    return _parent.fatal('[$_prefix] $message');
  }
}

class Logger implements AbstractLogger {
  static final Map<String, Logger?> _instances = {};

  String? _tmpPath;
  String? _docsPath;
  final String _name;
  late final StreamController<LogInfo> _logChannel;
  late final StreamSubscription<LogInfo> _logSubscription;
  IOSink? _logSink;
  final Map<String, WeakReference<CustomLogger>> _customInstances = {};

  factory Logger(String name) {
    _instances[name] ??= Logger._spawn(name);
    return _instances[name]!;
  }

  Logger._spawn(this._name) {
    _logChannel = StreamController<LogInfo>();
    _logSubscription = _logChannel.stream.listen(_write);
    _logSubscription.pause();
    getTemporaryDirectory().then((directory) {
      _tmpPath = path.join(directory.path, '$_name.log');
      _logSink = File(_tmpPath!).openWrite();
      _logSubscription.resume();
    });
  }

  void dispose() {
    _instances[_name] = null;
    _logSubscription.cancel();
    _logSink?.close();
    _logChannel.close();
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

  @override
  void info(String message) {
    _log(message, LogType.ltINFO);
  }

  @override
  void warning(String message) {
    _log(message, LogType.ltWARNING);
  }

  @override
  void error(String message) {
    _log(message, LogType.ltERROR);
  }

  @override
  Future<void> fatal(String message) {
    Completer completer = Completer();
    _log(message, LogType.ltFATAL, completer: completer);
    return completer.future;
  }

  CustomLogger custom(String prefix) {
    if (_customInstances[prefix]?.target == null) {
      _customInstances[prefix] = WeakReference(CustomLogger(prefix, this));
    }
    return _customInstances[prefix]!.target!;
  }
}
