import 'package:flutter/material.dart';
import 'dart:async';

import 'package:vdsinamonitor/globals/consts/colors.dart';
import 'package:vdsinamonitor/globals/consts/strings.dart';
import 'package:vdsinamonitor/ui/splash.dart';
import 'package:vdsinamonitor/globals/typedefs.dart';
import 'package:vdsinamonitor/bl/initialization.dart';

void main() {
  Completer<ResultEx> completer = Completer();
  runApp(VDSinaApplication(completer));
  initialize(completer);
}

class VDSinaApplication extends StatelessWidget {
  final Completer<ResultEx> _completer;
  const VDSinaApplication(Completer<ResultEx> completer, {super.key}):
    _completer=completer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: applicationTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: applicationMainColor),
        useMaterial3: true,
      ),
      home: SplashWindow(_completer),
    );
  }
}