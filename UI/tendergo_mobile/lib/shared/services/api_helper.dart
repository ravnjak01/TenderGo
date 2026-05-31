import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';

class ApiHelper {
  static ApiResponse<T> handleDioError<T>(DioException e) {
    final statusCode = e.response?.statusCode ?? 400;

    if (e.response?.data != null && e.response?.data is Map) {
      final responseData = e.response!.data as Map<String, dynamic>;

      Map<String, List<String>>? parsedFieldErrors;
      if (responseData['errors'] != null && responseData['errors'] is Map) {
        var errorsJson = responseData['errors'] as Map<String, dynamic>;
        parsedFieldErrors = errorsJson.map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }

      return ApiResponse<T>.failure(
        responseData['message']?.toString() ?? 'Došlo je do greške.',
        statusCode: statusCode,
        fieldErrors: parsedFieldErrors,
      );
    }

    return ApiResponse<T>.failure(
      'Greška u komunikaciji sa serverom.',
      statusCode: statusCode,
    );
  }
}
