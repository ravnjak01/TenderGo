import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/services/api_helper.dart';

extension UserMessageExtension on Object {

  String toUserMessage() {
    final error = this;

    if (error is ApiResponse) {
      return error.message ;
    }

    if (error is DioException) {
      final apiResponse = ApiHelper.handleDioError(error);
      return apiResponse.message ?? 'Greška u komunikaciji sa serverom.';
    }

    var message = error.toString();

    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    } else if (message.startsWith('FormatException: ')) {
      message = message.substring(17);
    }

    return message.trim();
  }
}