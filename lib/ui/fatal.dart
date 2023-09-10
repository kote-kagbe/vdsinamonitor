import 'package:flutter/material.dart';
import 'dart:async';

import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:vdsinamonitor/ui/accounts/list.dart';
import 'package:vdsinamonitor/globals/typedefs.dart';

class FatalErrorWindow extends StatelessWidget {
  const FatalErrorWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
          Icon(Icons.error_outline_rounded, color: Color(0xFFC70D00)),
          Text('Произошла критическая ошибка\nпродолжение работы невозможно'),
        ])));
  }
}
