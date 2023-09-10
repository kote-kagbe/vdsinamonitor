import 'dart:async';

import 'package:vdsinamonitor/bl/config.dart';
import 'package:vdsinamonitor/bl/logger.dart';
import 'package:vdsinamonitor/globals/consts/strings.dart';

final appAuthChannel = StreamController<bool>.broadcast();
final userErrorsChannel = StreamController<bool>.broadcast();

final config = Config();

final logger = Logger(applicationTitleMerged);
