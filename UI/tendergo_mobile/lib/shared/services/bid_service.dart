import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/error/bid_error_handler.dart';
import 'package:tendergo/shared/core/network/constants/bid_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/requests/bid_insert_request.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class BidService {
  final Dio _dio;

  BidService(this._dio);

  T _unwrapEnvelope<T>(Response response, T Function(dynamic data) mapper) {
    return mapper(ResponseParser.data(response.data));
  }


Future<PagedResult<BidDto>> getMyBids({int page = 1, int pageSize = 3}) async {
  try {
    final response = await _dio.get(
      BidApiEndpoints.getMyBids,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    return _unwrapEnvelope(
      response,
      (data) => PagedResult.fromJson(data as Map<String, dynamic>, BidDto.fromJson),
    );
  } on DioException catch (e) {
    throw _handleError(e, 'Greška pri učitavanju ponuda korisnika');
  }
}
  Future<BidDto> getById(int id) async {
    try {
      final response = await _dio.get(BidApiEndpoints.getById(id));

      return _unwrapEnvelope(response, (data) => BidDto.fromJson(data as Map<String, dynamic>));
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

 Future<PagedResult<BidDto>> getByTender(
  int tenderId, {
  int page = 1,
  int pageSize = 3,
}) async {
  try {
    final response = await _dio.get(
      BidApiEndpoints.getByTender(tenderId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    return _unwrapEnvelope(
      response,
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        BidDto.fromJson,
      ),
    );
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return PagedResult<BidDto>(
        result: [],
        totalCount: 0,
        page: page,
        pageSize: pageSize,
      );
    }
    if (e.response?.statusCode == 403) {
      throw Exception('You are not allowed to view bids for this tender.');
    }
    throw _handleError(e, 'Error fetching bids by tender');
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
