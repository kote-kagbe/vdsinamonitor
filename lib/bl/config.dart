import 'package:vdsinamonitor/globals/intercom.dart';

class Config {
  //задан ли локальный пароль
  bool _localAuthSet = false;

  bool get localAuthSet => _localAuthSet;

  //состояние локальной аутентификации
  bool localAuth = false;

  Future<bool> authenticateLocal(String password) async {
    return await Future.delayed(const Duration(seconds: 4), () {
      localAuth = true;
      appAuthChannel.add(localAuth);
      return localAuth;
    });
  }
}
