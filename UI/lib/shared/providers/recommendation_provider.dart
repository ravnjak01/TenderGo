import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/recommendation_service.dart';

enum RecommendationState { idle, loading, loaded, error }

class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _service;

  RecommendationProvider({RecommendationService? service, Dio? dio})
      : _service = service ?? RecommendationService(dio ?? DioClient.getDio());

  // ----------------------------------------------------------------
  // State
  // ----------------------------------------------------------------

  RecommendationState _state = RecommendationState.idle;
  List<TenderRecommendation> _recommendations = [];
  String? _errorMessage;

  RecommendationState get state => _state;
  List<TenderRecommendation> get recommendations => _recommendations;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == RecommendationState.loading;
  bool get hasData => _recommendations.isNotEmpty;

  // ----------------------------------------------------------------
  // Actions
  // ----------------------------------------------------------------

  /// Load tenders similar to a specific tender (for detail page)
  Future<void> loadSimilar({
    required int tenderId,
    required String authToken,
  }) async {
    _setState(RecommendationState.loading);

    try {
      _recommendations = await _service.getSimilarTenders(
        tenderId: tenderId,
        authToken: authToken,
      );
      _setState(RecommendationState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(RecommendationState.error);
    }
  }

  /// Load personalized recommendations (for home/dashboard page)
  Future<void> loadForUser({required String authToken}) async {
    _setState(RecommendationState.loading);

    try {
      _recommendations = await _service.getForCurrentUser(
        authToken: authToken,
      );
      _setState(RecommendationState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(RecommendationState.error);
    }
  }

  void clear() {
    _recommendations = [];
    _errorMessage = null;
    _setState(RecommendationState.idle);
  }

  void _setState(RecommendationState newState) {
    _state = newState;
    notifyListeners();
  }
}