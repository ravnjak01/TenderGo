class AuthResult<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, List<String>>? fieldErrors;

  AuthResult({
    required this.success,
    required this.message,
    this.data,
    this.fieldErrors,
  });

  factory AuthResult.success(T data, {String message = "Success"}) {
    return AuthResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory AuthResult.failure(String message, {Map<String, List<String>>? errors}) {
    return AuthResult(
      success: false,
      message: message,
      fieldErrors: errors,
    );
  }
}