import 'package:flutter/material.dart';

import 'package:vdsinamonitor/globals/consts/strings.dart';
import 'package:vdsinamonitor/ui/auth/application.dart';
import 'package:vdsinamonitor/ui/servers/list.dart';

class AccountListWindow extends StatefulWidget {
  const AccountListWindow({super.key});

  @override
  State<AccountListWindow> createState() => _AccountListWindowState();
}

class _AccountListWindowState extends AppAuthState<AccountListWindow> {
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
              'account list',
            ),
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) {
                  return const ServerListWindow();
                }));
              },
              icon: const Icon(Icons.lock_rounded),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
