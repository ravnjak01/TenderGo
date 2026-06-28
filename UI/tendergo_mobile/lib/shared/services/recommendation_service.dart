import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';
import 'package:tendergo/shared/core/network/constants/multiple_endpoints.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class RecommendationService {
  final Dio _dio;

  RecommendationService(this._dio);

  Future<List<TenderRecommendation>> getSimilarTenders({
    required int tenderId,
    int topN = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recommendSimilar(tenderId),
        queryParameters: {'topN': topN},
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju sličnih tendera');
    }
  }

  Future<List<TenderRecommendation>> getForCurrentUser({
    int topN = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recommendForUser,
        queryParameters: {'topN': topN},
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju preporuka za korisnika');
    }
  }

  Future<void> logSearchActivity({required String query}) async {
    try {
      await _dio.post(
        ApiEndpoints.userActivity,
        data: {
          "activityType": "Search",
          "searchQuery": query,
          "tenderId": null,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Neuspješno logovanje pretrage');
    }
  }

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
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Neuspješno logovanje pregleda tendera');
    }
  }

  List<TenderRecommendation> _parseList(dynamic responseData) {
    return ResponseParser.dtoList(responseData, TenderRecommendation.fromJson);
  }

  Exception _handleError(DioException e, String defaultMessage) {
    final message = ResponseParser.errorMessage(e, defaultMessage);

    return Exception(message);
  }
}
