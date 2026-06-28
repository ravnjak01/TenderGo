import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/error/bid_error_handler.dart';
import 'package:tendergo/shared/core/network/constants/bid_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/requests/bid_insert_request.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class BidService {
  final Dio _dio;

  BidService(this._dio);

  Future<List<BidDto>> getMyBids({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get(
        BidApiEndpoints.getMyBids,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      return ResponseParser.dtoList(response.data, BidDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching current user bids');
    }
  }

  Future<BidDto> getById(int id) async {
    try {
      final response = await _dio.get(BidApiEndpoints.getById(id));

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching bid');
    }
  }

  Future<BidDto> create(BidInsertRequest data) async {
    try {
      final response = await _dio.post(
        BidApiEndpoints.insert,
        data: data.toJson(),
      );

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error creating bid');
    }
  }

  Future<BidDto> withdraw(int id) async {
    try {
      final response = await _dio.patch(BidApiEndpoints.withdraw(id));

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error withdrawing bid');
    }
  }

  Future<List<BidDto>> getByTender(int tenderId) async {
    try {
      final response = await _dio.get(BidApiEndpoints.getByTender(tenderId));

      return ResponseParser.dtoList(response.data, BidDto.fromJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      if (e.response?.statusCode == 403) {
        throw Exception('You are not allowed to view bids for this tender.');
      }
      throw _handleError(e, 'Error fetching bids by tender');
    }
  }

  Future<BidDto> cancel(int id) async {
    try {
      final response = await _dio.put(BidApiEndpoints.cancel(id));

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error canceling tender');
    }
  }

  Future<List<dynamic>> getAllowedActions(int id) async {
    try {
      final response = await _dio.get(
        BidApiEndpoints.getAllowedActions(id),
      );

      return List<dynamic>.from(ResponseParser.list(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching bid actions');
    }
  }

  Exception _handleError(DioException e, String defaultMessage) {
    final message = ResponseParser.errorMessage(e, defaultMessage);
    if (BidErrorHandler.isDuplicateBidError(e, message)) {
      return BidAlreadyExistsException(message: message);
    }

    return BidServiceException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}
