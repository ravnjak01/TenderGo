// shared/utils/api_helper.dart
import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';

class ApiHelper {
 static ApiResponse<T> handleDioError<T>(DioException e) {
    // Izvlačimo status kod direktno iz DioException-a ako postoji (npr. 400, 404, 500)
    final statusCode = e.response?.statusCode ?? 400;

    if (e.response?.data != null && e.response?.data is Map) {
      final responseData = e.response!.data as Map<String, dynamic>;

      Map<String, List<String>>? parsedFieldErrors;
      if (responseData['errors'] != null && responseData['errors'] is Map) {
        var errorsJson = responseData['errors'] as Map<String, dynamic>;
        parsedFieldErrors = errorsJson.map(
          (key, value) => MapEntry(key, List<String>.from(value as List))
        );
      }

      // KORISTIMO NOVI KONSTRUKTOR ZA GREŠKU:
      return ApiResponse<T>.failure(
        responseData['message']?.toString() ?? 'Došlo je do greške.',
        statusCode: statusCode,
        fieldErrors: parsedFieldErrors,
      );
    }

    // Ako server uopšte nije odgovorio (npr. nema interneta ili je server ugašen)
    return ApiResponse<T>.failure(
      'Greška u komunikaciji sa serverom.',
      statusCode: statusCode, // Ovdje će proslijediti uhvaćeni status ili 400
    );
  }
}