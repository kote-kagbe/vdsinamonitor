import 'dart:async';

import 'package:vdsinamonitor/bl/config.dart';
import 'package:vdsinamonitor/bl/logger.dart';

final appAuthChannel = StreamController<bool>.broadcast();
final userErrorsChannel = StreamController<bool>.broadcast();

final config = Config();
final logger = Logger('VDSinaMonitor');
