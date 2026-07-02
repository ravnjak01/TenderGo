class ApiResponse<T> {
  final bool success;
  final String message;
  final int statusCode;
  final String? traceId;
  final T? data;
  
  final List<String>? errors;
  final Map<String, List<String>>? fieldErrors;

  ApiResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    this.traceId,
    this.data,
    this.errors,
    this.fieldErrors,
  });

  factory ApiResponse.success(T data, {String message = "Success", int statusCode = 200}) {
    return ApiResponse<T>(
      success: true,
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  factory ApiResponse.failure(String message, {int statusCode = 400, Map<String, List<String>>? fieldErrors, List<String>? errors}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
      errors: errors,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? json)? dataParser,
  }) {
    Map<String, List<String>>? parsedFieldErrors;
    if (json['fieldErrors'] != null) {
      parsedFieldErrors = (json['fieldErrors'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List).map((e) => e.toString()).toList()),
      );
    }

    return ApiResponse<T>(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      traceId: json['traceId']?.toString(),
      errors: (json['errors'] as List?)?.map((e) => e.toString()).toList(),
      fieldErrors: parsedFieldErrors,
      data: dataParser != null ? dataParser(json['data']) : null,
    );
  }
}