class AuthResult {
  final bool success;
  final String message;
  final dynamic data;

  const AuthResult({
    required this.success,
    required this.message,
    this.data,
  });
}