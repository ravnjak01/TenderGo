import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/multiple_endpoints.dart';
import 'package:tendergo/shared/models/requests/activity_log_request.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/services/api_helper.dart';

class UserActivityService {
  final Dio _dio;

  UserActivityService(this._dio);

  Future<ApiResponse<void>> logActivity(ActivityLogRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.userActivity,
        data: request.toJson(),
        options: await _options(),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          null,
          message: 'Activity logged successfully.',
        );
      }

      return ApiResponse.failure(
        'Failed to log user activity.',
        statusCode: response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      return ApiHelper.handleDioError<void>(e);
    }
  }

  Future<Options> _options() async {
    return Options(
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
}
