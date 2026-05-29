import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';

class RecommendationService {
  final Dio _dio;

  RecommendationService(this._dio);

  /// Returns tenders similar to [tenderId].
  /// Call this on a "Tender Detail" page to show related tenders.
  Future<List<TenderRecommendation>> getSimilarTenders({
    required int tenderId,
    required String authToken,
    int topN = 10,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.recommendSimilar(tenderId),
      queryParameters: {'topN': topN},
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    return _parseList(response.data);
  }

  /// Returns personalized recommendations for the logged-in user
  /// based on their bid history.
  /// Call this on the Home / Dashboard screen.
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

  /// Log when user views a tender
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

  // ----------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------

  List<TenderRecommendation> _parseList(dynamic body) {
    final List<dynamic> data = body is List
        ? body
        : (body['recommendations'] ?? []) as List<dynamic>;
    return data
        .map((e) => TenderRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
