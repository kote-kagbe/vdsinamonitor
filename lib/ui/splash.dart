import 'package:flutter/material.dart';
import 'dart:async';

import 'package:vdsinamonitor/bl/initialization.dart';
import 'package:vdsinamonitor/ui/accounts/list.dart';
import 'package:vdsinamonitor/globals/typedefs.dart';

bool firstRun = true;

class SplashWindow extends StatelessWidget {
  final Completer<ResultEx> _completer;
  const SplashWindow(Completer<ResultEx> completer, {super.key}):
    _completer=completer;

  @override
  Widget build(BuildContext context) {
    if(firstRun) {
      _completer.future.then((_){
        Navigator.pushReplacement<void, void>(
            context,
            MaterialPageRoute(builder: (_) {
              return const AccountListWindow();
            })
        );
      });
      firstRun = false;
    }
    return const Scaffold(
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Подождите, пожалуйста...'),
              CircularProgressIndicator(),
            ]
        )
      )
    );
  }
}