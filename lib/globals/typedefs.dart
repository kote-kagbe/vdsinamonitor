enum ResultCode {
  rcInfo,
  rcWarning,
  rcError,
}
typedef ResultDetails = ({ResultCode? code, String? message});
typedef ResultEx = ({bool result, ResultDetails? details});