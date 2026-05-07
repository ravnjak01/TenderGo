import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/notification_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';

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

  /// Returns all notifications for the logged-in user.
  Future<List<NotificationDto>> getMyNotifications() async {
    final response = await _dio.get(
      NotificationApiEndpoints.getMy,
      options: await _options(),
    );
    final body = response.data;
    final List<dynamic> list =
        body is List ? body : (body['notifications'] ?? body['data'] ?? []);
    return list
        .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Marks a single notification as read. Returns updated dto on 200.
  Future<void> markAsRead(int id) async {
    await _dio.patch(
      NotificationApiEndpoints.markAsRead(id),
      options: await _options(),
    );
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    await _dio.patch(
      NotificationApiEndpoints.markAllAsRead,
      options: await _options(),
    );
  }

  /// Deletes a notification.
  Future<void> delete(int id) async {
    await _dio.delete(
      NotificationApiEndpoints.delete(id),
      options: await _options(),
    );
  }
}
