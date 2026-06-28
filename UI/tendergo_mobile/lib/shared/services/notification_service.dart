import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/notification_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<NotificationDto>> getMyNotifications() async {
    try {
      final response = await _dio.get(NotificationApiEndpoints.getMy);
      return ResponseParser.dtoList(response.data, NotificationDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching notifications');
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dio.patch(NotificationApiEndpoints.markAsRead(id));
    } on DioException catch (e) {
      throw _handleError(e, 'Error marking notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch(NotificationApiEndpoints.markAllAsRead);
    } on DioException catch (e) {
      throw _handleError(e, 'Error marking all notifications as read');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete(NotificationApiEndpoints.delete(id));
    } on DioException catch (e) {
      throw _handleError(e, 'Error deleting notification');
    }
  }

  Exception _handleError(DioException e, String defaultMessage) {
    final message = ResponseParser.errorMessage(e, defaultMessage);
    return Exception(message);
  }
}
