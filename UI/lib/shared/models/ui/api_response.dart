class ApiResponse<T> {
  final bool success;
  final String message;
  final List<String>? errors;
  final int statusCode;
  final String traceId;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.traceId,
    this.errors,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? json)? dataParser,
  }) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      errors: (json['errors'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      traceId: (json['traceId'] ?? '').toString(),
      data: dataParser != null ? dataParser(json['data']) : null,
    );
  }
}