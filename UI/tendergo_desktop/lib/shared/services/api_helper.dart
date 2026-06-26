import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/error/error_handler.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';

class ApiHelper {
  static ApiResponse<T> handleDioError<T>(
    DioException e, {
    String fallbackMessage = 'Greška u komunikaciji sa serverom.',
  }) {
    final statusCode = e.response?.statusCode ?? 400;
    final data = e.response?.data;

    if (ErrorHandler.isAccountBanned(data)) {
      return ApiResponse<T>.failure(
        ErrorHandler.accountBannedMessage(),
        statusCode: statusCode,
      );
    }

    if (data is Map<String, dynamic>) {
      Map<String, List<String>>? parsedFieldErrors;

      final errors = data['fieldErrors'] ?? data['errors'];

      if (errors is Map) {
        parsedFieldErrors = errors.map(
          (key, value) {
            final values = value is List
                ? value.map((e) => e.toString()).toList()
                : [value.toString()];

            return MapEntry(key.toString(), values);
          },
        );
      }

      final message =
          ErrorHandler.extractErrorMessage(data) ??
          data['message']?.toString() ??
          fallbackMessage;

      return ApiResponse<T>.failure(
        message,
        statusCode: statusCode,
        fieldErrors: parsedFieldErrors,
      );
    }

    return ApiResponse<T>.failure(
      fallbackMessage,
      statusCode: statusCode,
    );
  }
}