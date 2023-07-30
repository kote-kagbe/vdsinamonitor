import 'package:flutter/material.dart';

import 'package:vdsinamonitor/globals/consts/colors.dart';
import 'package:vdsinamonitor/globals/consts/strings.dart';
import 'package:vdsinamonitor/ui/splash.dart';

void main() {
  runApp(const VDSinaApplication());
}

class VDSinaApplication extends StatelessWidget {
  const VDSinaApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: applicationTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: applicationMainColor),
        useMaterial3: true,
      ),
      home: const SplashWindow(),
    );
  }
}