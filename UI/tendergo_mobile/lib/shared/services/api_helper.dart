import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';

class ApiHelper {
  static ApiResponse<T> handleDioError<T>(DioException e) {
    final statusCode = e.response?.statusCode ?? 400;

    if (e.response?.data != null && e.response?.data is Map) {
      final responseData = e.response!.data as Map<String, dynamic>;

      final rawMessage = responseData['message']?.toString();
      final rawErrors = responseData['errors'];

      List<String> parsedErrors = [];

      // Backend vraća 'errors' kao List<string> (npr. ["Field: Error message"])
      if (rawErrors is List) {
        parsedErrors = rawErrors.map((err) => err.toString()).toList();
      }

      // Ako imamo niz grešaka, spajamo ih ili prosljeđujemo u poruku
      final finalMessage = parsedErrors.isNotEmpty 
          ? parsedErrors.join('\n') 
          : (rawMessage ?? 'Došlo je do greške.');

      return ApiResponse<T>.failure(
        finalMessage,
        statusCode: statusCode,
      );
    }

    return ApiResponse<T>.failure(
      'Greška u komunikaciji sa serverom.',
      statusCode: statusCode,
    );
  }
}