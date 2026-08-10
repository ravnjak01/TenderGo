import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class TenderService {
  final Dio _dio;
  final ImageService _imageService;

  TenderService(this._dio, this._imageService);

  ImageService get imageService => _imageService;

  T _unwrapEnvelope<T>(Response response, T Function(dynamic data) mapper) {
    return mapper(ResponseParser.data(response.data));
  }

  Exception _handleError(DioException e, String defaultMessage) {
    return Exception(ResponseParser.errorMessage(e, defaultMessage));
  }


Future<PagedResult<TenderDto>> get({
  TenderSearchRequest? request,
}) async {
  try {
    final searchParams = request ?? TenderSearchRequest(page: 1, pageSize: 10);

    final response = await _dio.get(
      TenderApiEndpoints.get, 
      queryParameters: searchParams.toQueryParams(),
    );

    return _unwrapEnvelope(
      response,
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>, 
        TenderDto.fromJson,
      ),
    );
  } on DioException catch (e) {
    throw _handleError(e, 'Greška pri dohvaćanju tendera');
  }
}

  Future<TenderDto> getById(int id) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getById(id));
      return _unwrapEnvelope(response, (data) => TenderDto.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju detalja tendera');
    }
  }



  Future<TenderDto> create(
    TenderInsertRequest data, {
    List<PlatformFile>? imageFiles,
  }) async {
    try {
      final uploadedImages = imageFiles == null || imageFiles.isEmpty
          ? data.images
          : await _imageService.uploadAll(imageFiles);
      final request = TenderInsertRequest(
        title: data.title,
        maxBudget: data.maxBudget,
        locationId: data.locationId,
        description: data.description,
        categoryId: data.categoryId,
        deadline: data.deadline,
        images: uploadedImages,
      );
      final response = await _dio.post(
        TenderApiEndpoints.insert,
        data: request.toJson(),
      );

      return _unwrapEnvelope(
        response,
        (data) => TenderDto.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri kreiranju tendera');
    }
  }

  Future<TenderDto> award(TenderDto tender, int bidId) async {
    try {
      final response = await _dio.patch(TenderApiEndpoints.award(tender, bidId));
      return _unwrapEnvelope(response, (data) => TenderDto.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri dodjeljivanju tendera');
    }
  }

  Future<TenderDto> cancel(int id) async {
    try {
      final response = await _dio.patch(TenderApiEndpoints.cancel(id));
      return _unwrapEnvelope(response, (data) => TenderDto.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri otkazivanju tendera');
    }
  }



Future<PagedResult<TenderDto>> getByUser(
  String userId, {
  int page = 1,
  int pageSize = 10,
}) async {
  try {
    final response = await _dio.get(
      TenderApiEndpoints.getByUser(userId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    return _unwrapEnvelope(
      response,
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        TenderDto.fromJson,
      ),
    );
  } on DioException catch (e) {
    if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
      return PagedResult(
        result: const [],
        totalCount: 0,
        page: 1,
        pageSize: 10,
      );
    }

    throw _handleError(e, 'Greška pri dohvaćanju korisničkih tendera');
  }
}


  Future<bool> toggleBookmark(int tenderId) async {
    try {
      final response = await _dio.post(TenderApiEndpoints.toggleBookmark(tenderId));
      final data = ResponseParser.data(response.data);
      return data is bool ? data : false;
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri izmjeni bookmark-a');
    }
  }

Future<PagedResult<TenderDto>> getBookmarked({
  int page = 1,
  int pageSize = 10,
}) async {
  try {
    final response = await _dio.get(
      TenderApiEndpoints.getBookmarks,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    return _unwrapEnvelope(
      response,
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        TenderDto.fromJson,
      ),
    );
  } on DioException catch (e) {
    throw _handleError(e, 'Greška pri učitavanju bookmark-ovanih tendera');
  }
}
}
