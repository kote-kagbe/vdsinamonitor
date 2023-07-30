import 'dart:async';

import 'package:vdsinamonitor/bl/config.dart';

final appAuthChannel = StreamController<bool>.broadcast();

final config = Config();