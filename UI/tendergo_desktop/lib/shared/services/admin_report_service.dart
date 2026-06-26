import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/admin_report_endpoints.dart';
import 'package:tendergo/shared/models/dto/admin_report_overview_dto.dart';
import 'package:tendergo/shared/models/requests/admin_report_request.dart';

class AdminReportService {
  final Dio _dio;

  AdminReportService(this._dio);

  Future<AdminReportOverviewDto> getOverview([AdminReportRequest? request]) async {
    try {
      final response = await _dio.get(
        AdminReportEndpoints.overview,
        queryParameters: request?.toJson(),
      );

      final raw = response.data;
      final payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw['result'] is Map<String, dynamic>
                  ? raw['result'] as Map<String, dynamic>
                  : raw)
          : <String, dynamic>{};
      return AdminReportOverviewDto.fromJson(Map<String, dynamic>.from(payload));
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching admin report overview');
    }
  }

  Future<List<Map<String, dynamic>>> getTendersByLocation([AdminReportRequest? request]) async {
    try {
      final response = await _dio.get(
        AdminReportEndpoints.tendersByLocation,
        queryParameters: request?.toJson(),
      );

      final raw = response.data;
      final listData = raw is List
          ? raw
          : raw is Map<String, dynamic>
              ? (raw['result'] is List
                  ? raw['result'] as List
                  : raw['data'] is List
                      ? raw['data'] as List
                      : [])
              : [];

      return listData
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching tenders by location');
    }
  }
Future<Uint8List?> fetchUserTenderReportPdf(String userId) async {
  try {
    final response = await _dio.get(
      AdminReportEndpoints.userTenderReport(userId),
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode == 200 && response.data != null) {
      return Uint8List.fromList(response.data as List<int>);
    }

    return null;
  } on DioException catch (e) {
    throw Exception(
      e.response?.data ?? 'Error generating user report PDF',
    );
  }
}

  Future<Uint8List?> fetchLocationReportPdf({
    required int locationId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _dio.get(
        AdminReportEndpoints.tendersByLocation,
        queryParameters: AdminReportRequest(
          locationId: locationId,
          from: from,
          to: to,
        ).toJson(),
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data as List<int>);
      }

      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error generating location report PDF');
    }
  }
}
