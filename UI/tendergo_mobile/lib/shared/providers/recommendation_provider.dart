import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/recommendation_service.dart';

enum RecommendationState { idle, loading, loaded, error }

class RecommendationProvider extends BaseProvider {
  final RecommendationService _service;

  RecommendationProvider({RecommendationService? service, Dio? dio})
    : _service = service ?? RecommendationService(dio ?? DioClient.getDio());

  RecommendationState _state = RecommendationState.idle;
  List<TenderRecommendation> _recommendations = [];

  RecommendationState get state => _state;
  List<TenderRecommendation> get recommendations => _recommendations;
  String? get errorMessage => error;

  @override
  bool get isLoading => _state == RecommendationState.loading;

  bool get hasData => _recommendations.isNotEmpty;

  Future<void> loadSimilar({
    required int tenderId,
  }) async {
    _state = RecommendationState.loading;
    await handleAsync(() async {
      _recommendations = await _service.getSimilarTenders(
        tenderId: tenderId,
      );
      _state = RecommendationState.loaded;
    }, onError: (_) => _state = RecommendationState.error);
  }

  Future<void> loadForUser() async {
    _state = RecommendationState.loading;
    await handleAsync(() async {
      _recommendations = await _service.getForCurrentUser();
      _state = RecommendationState.loaded;
    }, onError: (_) => _state = RecommendationState.error);
  }

  void clear() {
    _recommendations = [];
    _state = RecommendationState.idle;
    clearError();
  }
}
