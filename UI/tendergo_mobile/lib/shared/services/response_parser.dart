import 'package:dio/dio.dart';

class ResponseParser {
  ResponseParser._();

  /// Izvlači 'data' iz ApiSuccessEnvelope omotača
  static dynamic data(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  static Map<String, dynamic> object(dynamic responseData) {
    final payload = data(responseData);

    if (payload is Map<String, dynamic>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    throw Exception('Invalid response format: data is not an object.');
  }

  static List<dynamic> list(dynamic responseData) {
    final payload = data(responseData);

    if (payload == null) {
      return [];
    }

    if (payload is List) {
      return payload;
    }

   if (payload is Map<String, dynamic>) {
    final listPayload = payload['result'];
    if (listPayload is List) {
      return listPayload;
    }
  }

    throw Exception('Invalid response format: data is not a list.');
  }

  static List<T> dtoList<T>(
    dynamic responseData,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return list(responseData)
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  /// Ekstraktuje poruku o grešci iz ApiErrorEnvelope omotača
  static String errorMessage(DioException e, String fallback) {
    final resData = e.response?.data;

    if (resData is Map<String, dynamic>) {
      final errors = resData['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join('\n');
      }

      final message = resData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}