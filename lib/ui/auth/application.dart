import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:vdsinamonitor/globals/consts/strings.dart';
import 'package:vdsinamonitor/globals/intercom.dart';
import 'package:vdsinamonitor/ui/utils.dart';

class AppAuthWindow extends StatefulWidget {
  const AppAuthWindow({super.key});

  @override
  State<AppAuthWindow> createState() => _AppAuthWindowState();
}

class _AppAuthWindowState extends State<AppAuthWindow> {
  final password = TextEditingController();

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordFieldSidePadding = deviceWidth(context) / 4;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text(applicationTitle),
        ),
        body: LoaderOverlay(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${config.localAuthSet ? 'Введите' : 'Придумайте'} пароль приложения',
                ),
                Container(
                  padding: EdgeInsets.only(
                      left: passwordFieldSidePadding,
                      right: passwordFieldSidePadding),
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: password,
                    obscureText: config.localAuthSet ? true : false,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (password.text.isNotEmpty) {
                      config
                          .authenticateLocal(password.text)
                          .then((value) => context.loaderOverlay.hide());
                      context.loaderOverlay.show();
                    }
                  },
                  icon: config.localAuthSet
                      ? const Icon(Icons.lock_open_rounded)
                      : const Icon(Icons.lock_rounded),
                ),
              ],
            ),
          ),
        ));
  }
}

abstract class AppAuthState<T extends StatefulWidget> extends State<T> {
  late final StreamSubscription<bool> appAuthSubscription;

  @override
  void initState() {
    super.initState();
    appAuthSubscription = appAuthChannel.stream.listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    appAuthSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return config.localAuth ? buildOwn(context) : const AppAuthWindow();
  }

  @protected
  Widget buildOwn(BuildContext context);
}
