import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/error/bid_error_handler.dart';
import 'package:tendergo/shared/core/network/constants/bid_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/requests/bid_insert_request.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class BidService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  BidService(this._dio);

  Future<String?> _getToken() async => await _storage.read(key: 'jwt_token');

  Future<Options> _options() async {
    final token = await _getToken();
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // Odgovara [HttpGet("my-bids")]
// Dodaj opcionalne imenovane parametre nazad u potpis metode
  Future<List<BidDto>> getMyBids({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get(
        BidApiEndpoints.getMyBids,
        // Prosljeđujemo ih backendu kao query string (?page=1&pageSize=10)
        queryParameters: {'page': page, 'pageSize': pageSize}, 
        options: await _options(),
      );

      return ResponseParser.dtoList(response.data, BidDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching current user bids');
    }
  }

  // Odgovara [HttpGet("{id}")]
  Future<BidDto> getById(int id) async {
    try {
      final response = await _dio.get(
        BidApiEndpoints.getById(id),
        options: await _options(),
      );

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching bid');
    }
  }

  // Odgovara [HttpPost]
  Future<BidDto> create(BidInsertRequest data) async {
    try {
      final response = await _dio.post(
        BidApiEndpoints.insert,
        data: data.toJson(),
        options: await _options(),
      );

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error creating bid');
    }
  }

  // Odgovara [HttpPatch("{id}/withdraw")]
  Future<BidDto> withdraw(int id) async {
    try {
      final response = await _dio.patch(
        BidApiEndpoints.withdraw(id),
        options: await _options(),
      );

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error withdrawing bid');
    }
  }

  // Odgovara [HttpGet("tender/{tenderId}")]
  Future<List<BidDto>> getByTender(int tenderId) async {
    try {
      final response = await _dio.get(
        BidApiEndpoints.getByTender(tenderId),
        options: await _options(),
      );

      return ResponseParser.dtoList(response.data, BidDto.fromJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      if (e.response?.statusCode == 403) {
        throw Exception('You are not allowed to view bids for this tender.');
      }
      throw _handleError(e, 'Error fetching bids by tender');
    }
  }

  // Odgovara [HttpPut("{id}/cancel")]
  Future<BidDto> cancel(int id) async {
    try {
      final response = await _dio.put(
        BidApiEndpoints.cancel(id),
        options: await _options(),
      );

      return BidDto.fromJson(ResponseParser.object(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error canceling tender');
    }
  }

  // Odgovara [HttpGet("{id}/allowed-actions")]
  Future<List<dynamic>> getAllowedActions(int id) async {
    try {
      final response = await _dio.get(
        BidApiEndpoints.getAllowedActions(id),
        options: await _options(),
      );

      return List<dynamic>.from(ResponseParser.list(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Error fetching bid actions');
    }
  }

  // Centralizovano rukovanje greškama koje čita backend kovertu greške
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
