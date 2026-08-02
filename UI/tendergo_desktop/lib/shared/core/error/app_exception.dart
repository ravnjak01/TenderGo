class AppException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? errors;

  const AppException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message; 
}