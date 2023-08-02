import 'package:flutter/material.dart';
import 'dart:isolate';

import 'package:vdsinamonitor/bl/initialization.dart';
import 'package:vdsinamonitor/ui/accounts/list.dart';

bool firstRun = true;

class SplashWindow extends StatelessWidget {
  const SplashWindow({super.key});

  @override
  Widget build(BuildContext context) {
    if(firstRun) {
      initialize().then((_){
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