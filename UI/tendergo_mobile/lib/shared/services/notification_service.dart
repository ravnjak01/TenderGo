import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/notification_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

Future<PagedResult<NotificationDto>> getMyNotifications({
  int page = 1,
  int pageSize = 10,
}) async {
  try {
    final response = await _dio.get(
      NotificationApiEndpoints.getMy,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    // Pretvaramo sirovi odgovor preko ResponseParser-a u Map<String, dynamic>
    final rawData = ResponseParser.data(response.data) as Map<String, dynamic>;

    // Direktno instanciramo PagedResult sa podacima
    return PagedResult.fromJson(rawData, NotificationDto.fromJson);
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
