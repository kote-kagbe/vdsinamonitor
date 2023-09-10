import 'package:flutter/material.dart';
import 'dart:async';

import 'package:vdsinamonitor/ui/accounts/list.dart';
import 'package:vdsinamonitor/globals/typedefs.dart';

bool firstRun = true;

class SplashWindow extends StatelessWidget {
  final Completer<ResultEx> _completer;

  const SplashWindow(this._completer, {super.key});

  @override
  Widget build(BuildContext context) {
    if (firstRun) {
      _completer.future.then((_) {
        Navigator.pushReplacement<void, void>(context,
            MaterialPageRoute(builder: (_) {
          return const AccountListWindow();
        }));
      }).catchError((err) {
        //
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
        ])));
  }
}
