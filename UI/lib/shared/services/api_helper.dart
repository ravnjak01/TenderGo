// shared/utils/api_helper.dart
import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';

class ApiHelper {
  static AuthResult<T> handleDioError<T>(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final responseData = e.response!.data;

      Map<String, List<String>>? parsedFieldErrors;
      if (responseData['errors'] != null) {
        var errorsJson = responseData['errors'] as Map<String, dynamic>;
        parsedFieldErrors = errorsJson.map(
          (key, value) => MapEntry(key, List<String>.from(value as List))
        );
      }

      return AuthResult<T>(
        success: false,
        message: responseData['message']?.toString() ?? 'Došlo je do greške.',
        fieldErrors: parsedFieldErrors,
      );
    }

    return AuthResult<T>(
      success: false,
      message: 'Greška u komunikaciji sa serverom.',
    );
  }
}