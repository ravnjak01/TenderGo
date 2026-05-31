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

  Future<List<NotificationDto>> getMyNotifications() async {
    final response = await _dio.get(
      NotificationApiEndpoints.getMy,
      options: await _options(),
    );
    final body = response.data;
    final List<dynamic> list = body is List
        ? body
        : (body['notifications'] ?? body['data'] ?? []);
    return list
        .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await _dio.patch(
      NotificationApiEndpoints.markAsRead(id),
      options: await _options(),
    );
  }

  Future<void> markAllAsRead() async {
    await _dio.patch(
      NotificationApiEndpoints.markAllAsRead,
      options: await _options(),
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete(
      NotificationApiEndpoints.delete(id),
      options: await _options(),
    );
  }

  Future<void> testExpiredTender(int tenderId) async {
    await _dio.post(
      NotificationApiEndpoints.testExpiredTender(tenderId),
      options: await _options(),
    );
  }

  Future<void> testAssignedTender(int bidId) async {
    await _dio.post(
      NotificationApiEndpoints.testAssignedTender(bidId),
      options: await _options(),
    );
  }
}
