import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';
import 'package:tendergo/shared/core/network/constants/multiple_endpoints.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class RecommendationService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  RecommendationService(this._dio);

  // Pomoćna metoda za automatsko dovlačenje tokena i zaglavlja
  Future<Options> _options() async {
    final token = await _storage.read(key: 'jwt_token');
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // Odgovara [HttpGet("similar/{tenderId:int}")]
  Future<List<TenderRecommendation>> getSimilarTenders({
    required int tenderId,
    int topN = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recommendSimilar(tenderId),
        queryParameters: {'topN': topN},
        options: await _options(),
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju sličnih tendera');
    }
  }

  // Odgovara [HttpGet("for-user")]
  Future<List<TenderRecommendation>> getForCurrentUser({
    int topN = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recommendForUser,
        queryParameters: {'topN': topN},
        options: await _options(),
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju preporuka za korisnika');
    }
  }

  // Logovanje aktivnosti pretrage
  Future<void> logSearchActivity({required String query}) async {
    try {
      await _dio.post(
        ApiEndpoints.userActivity,
        data: {
          "activityType": "Search",
          "searchQuery": query,
          "tenderId": null,
        },
        options: await _options(),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Neuspješno logovanje pretrage');
    }
  }

  // Logovanje aktivnosti pregleda tendera
  Future<void> logViewActivity({
    required int tenderId,
    required int durationSeconds,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.userActivity,
        data: {
          "activityType": "View",
          "tenderId": tenderId,
          "searchQuery": null,
          "durationSeconds": durationSeconds,
        },
        options: await _options(),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Neuspješno logovanje pregleda tendera');
    }
  }

  // Strogo mapiranje liste iz 'data' polja koverte uspjeha
  List<TenderRecommendation> _parseList(dynamic responseData) {
    return ResponseParser.dtoList(responseData, TenderRecommendation.fromJson);
  }

  // Centralizovano rukovanje greškama iz ApiErrorEnvelope
  Exception _handleError(DioException e, String defaultMessage) {
    final message = ResponseParser.errorMessage(e, defaultMessage);

    return Exception(message);
  }
}
