import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';

class RecommendationService {
  final Dio _dio;

  RecommendationService(this._dio);

  Future<List<TenderRecommendation>> getSimilarTenders({
    required int tenderId,
    required String authToken,
    int topN = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recommendSimilar(tenderId),
        queryParameters: {'topN': topN},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      return _parseList(response.data);
    } on DioException catch (e) {

      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TenderRecommendation>> getForCurrentUser({
    required String authToken,
    int topN = 10,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.recommendForUser,
      queryParameters: {'topN': topN},
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    return _parseList(response.data);
  }

  Future<void> logSearchActivity({
    required String query,
    required String authToken,
  }) async {
    await _dio.post(
      ApiEndpoints.userActivity,
      data: {"activityType": "Search", "searchQuery": query, "tenderId": null},
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
  }

  Future<void> logViewActivity({
    required int tenderId,
    required String authToken,
    required int durationSeconds,
  }) async {
    await _dio.post(
      ApiEndpoints.userActivity,
      data: {
        "activityType": "View",
        "tenderId": tenderId,
        "searchQuery": null,
        "durationSeconds": durationSeconds,
      },
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
  }

  List<TenderRecommendation> _parseList(dynamic body) {
    final List<dynamic> data = body is List
        ? body
        : (body['recommendations'] ?? []) as List<dynamic>;
    return data
        .map((e) => TenderRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
