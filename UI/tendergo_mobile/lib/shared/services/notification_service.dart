import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/notification_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class NotificationService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  NotificationService(this._dio);

  Future<Options> _options() async {
    final token = await _storage.read(key: 'jwt_token');
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // Odgovara [HttpGet("my")]
  Future<List<NotificationDto>> getMyNotifications() async {
    try {
      final response = await _dio.get(
        NotificationApiEndpoints.getMy,
        options: await _options(),
      );
      return ResponseParser.dtoList(response.data, NotificationDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching notifications');
    }
  }

  // Odgovara [HttpPatch("{id:int}/read")]
  Future<void> markAsRead(int id) async {
    try {
      await _dio.patch(
        NotificationApiEndpoints.markAsRead(id),
        options: await _options(),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Error marking notification as read');
    }
  }

  // Odgovara [HttpPatch("read-all")]
  Future<void> markAllAsRead() async {
    try {
      await _dio.patch(
        NotificationApiEndpoints.markAllAsRead,
        options: await _options(),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Error marking all notifications as read');
    }
  }

  // Odgovara [HttpDelete("{id:int}")]
  Future<void> delete(int id) async {
    try {
      await _dio.delete(
        NotificationApiEndpoints.delete(id),
        options: await _options(),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Error deleting notification');
    }
  }

  // Centralizovano čitanje grešaka iz ApiErrorEnvelope
  Exception _handleError(DioException e, String defaultMessage) {
    final message = ResponseParser.errorMessage(e, defaultMessage);
    return Exception(message);
  }
}
