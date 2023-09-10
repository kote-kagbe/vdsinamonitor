import 'dart:core';

enum ResultCode {
  rcInfo,
  rcWarning,
  rcError,
  rcFatal,
}

typedef ResultDetails = ({
  ResultCode? code,
  String? message,
  String? userMessage
});

typedef ResultEx = ({bool result, ResultDetails? details});
