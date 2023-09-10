import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:vdsinamonitor/globals/consts/strings.dart';
import 'package:vdsinamonitor/globals/intercom.dart';

const String localAuthKey = '$applicationTitleMerged.localPassword';

class Config {
  final _logger = logger.custom('Config');

  //задан ли локальный пароль
  bool _localAuthSet = false;
  bool get localAuthSet => _localAuthSet;

  //состояние локальной аутентификации
  bool _localAuth = false;
  bool get localAuth => _localAuth;

  //биометрия
  bool _deviceAuth = false;
  bool get deviceAuth => _deviceAuth;

  Future<bool> authenticateLocal([String? password]) async {
    _logger.info(
        'локальная аутентификация ${password == null ? 'на устройстве' : 'по паролю'}');
    if (password != null) {
      const storage = FlutterSecureStorage();
      //пароль приложения нам не нужен, поэтому хранить его не будем
      final passwordMD5 = md5.convert(utf8.encode(password)).toString();
      if (_localAuthSet) {
        _logger.info('чтение пароля из хранилища');
        final value = await storage.read(key: localAuthKey);
        _localAuth = value == passwordMD5;
      } else {
        _logger.info('запись пароля в хранилище');
        await storage.write(key: localAuthKey, value: passwordMD5);
        _localAuth = true;
        _localAuthSet = true;
      }
    } else if (_deviceAuth) {
      final LocalAuthentication bio = LocalAuthentication();
      try {
        _localAuth = await bio.authenticate(
            localizedReason: 'Подтвердите аутентификацию на устройстве');
      } catch (e) {
        _logger.error('ошибка аутентификации: $e');
        _localAuth = false;
      }
    } else {
      _logger.warning('варианты аутентификации не отработали');
      _localAuth = false;
    }
    _logger.info('результат аутентификации: $_localAuth');
    appAuthChannel.add(_localAuth);
    return _localAuth;
  }

  Future<void> initialize() async {
    _logger.info('проверяем наличие пароля');
    _localAuthSet =
        await const FlutterSecureStorage().read(key: localAuthKey) != null;
    _logger.info('$_localAuthSet');

    _logger.info('проверяем наличие системы аутентификации на устройстве');
    final LocalAuthentication bio = LocalAuthentication();
    _deviceAuth = await bio.isDeviceSupported();
    _logger.info('$_deviceAuth');
  }
}
