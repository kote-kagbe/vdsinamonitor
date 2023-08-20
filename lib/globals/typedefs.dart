import 'dart:core';

enum ResultCode {
  rcInfo,
  rcWarning,
  rcError,
  rcFatal,
}
typedef TResultDetails = ({ResultCode? code, String? message, String? userMessage});
typedef TResultEx = ({bool result, TResultDetails? details});
