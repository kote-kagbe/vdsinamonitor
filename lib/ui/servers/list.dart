import 'package:flutter/material.dart';

import 'package:vdsinamonitor/globals/consts/strings.dart';
import 'package:vdsinamonitor/ui/auth/application.dart';

class ServerListWindow extends StatefulWidget {
  const ServerListWindow({super.key});

  @override
  State<ServerListWindow> createState() => _ServerListWindowState();
}

class _ServerListWindowState extends AppAuthState<ServerListWindow> {

  @override
  Widget buildOwn(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(applicationTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'server list',
            ),
            IconButton(
              onPressed: (){},
              icon: const Icon(Icons.lock_rounded),
            ),
          ],
        ),
      ),
    );
  }
}