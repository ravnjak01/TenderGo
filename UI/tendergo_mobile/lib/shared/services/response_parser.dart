import 'package:dio/dio.dart';

class ResponseParser {
  ResponseParser._();

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
      final nestedList = payload['result'] ??
          payload['Result'] ??
          payload['resultList'] ??
          payload['items'];

      if (nestedList is List) {
        return nestedList;
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

  static String errorMessage(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.join('\n');
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}
