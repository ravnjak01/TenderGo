import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';

class ApiHelper {
  static ApiResponse<T> handleDioError<T>(
    DioException e, {
    String fallbackMessage = 'Greška u komunikaciji sa serverom.',
  }) {
    final statusCode = e.response?.statusCode ?? 400;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      try {
        final parsedResponse = ApiResponse<T>.fromJson(data);
        
        if (parsedResponse.message.isEmpty) {
          return ApiResponse<T>.failure(
            fallbackMessage,
            statusCode: statusCode,
            errors: parsedResponse.errors,
            fieldErrors: parsedResponse.fieldErrors,
          );
        }
        
        return parsedResponse;
      } catch (_) {
      }
    }

    return ApiResponse<T>.failure(
      fallbackMessage,
      statusCode: statusCode,
    );
  }
}