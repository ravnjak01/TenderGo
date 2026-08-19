import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_cancel_request.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/base_service.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class TenderService extends BaseService<TenderDto> {
  final ImageService _imageService;

  TenderService(Dio dio, this._imageService)
      : super(dio, TenderApiEndpoints.get, TenderDto.fromJson);

  ImageService get imageService => _imageService;

  Future<PagedResult<TenderDto>> get({
    TenderSearchRequest? request,
  }) async {
    final searchParams = request ?? TenderSearchRequest(page: 1, pageSize: 10);
    
    return getPaged(
      page: searchParams.page,
      pageSize: searchParams.pageSize,
      queryParameters: searchParams.toQueryParams(),
    );
  }

  Future<TenderDto> create(
    TenderInsertRequest data, {
    List<PlatformFile>? imageFiles,
  }) async {
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

    return insert(request);
  }

  Future<TenderDto> award(TenderDto tender, int bidId) async {
    try {
      final response = await dio.patch(TenderApiEndpoints.award(tender, bidId));
      return parseJson(extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri dodjeljivanju tendera'));
    }
  }

  /// Otkazivanje tendera
 Future<TenderDto> cancel(int id, TenderCancelRequest request) async {
  try {
    final response = await dio.patch(
      TenderApiEndpoints.cancel(id),
      data: request.toJson(),
    );
    return parseJson(extractObject(response.data));
  } on DioException catch (e) {
    throw Exception(extractErrorMessage(e, 'Greška pri otkazivanju tendera'));
  }
}

  Future<PagedResult<TenderDto>> getByUser(
    String userId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await dio.get(
        TenderApiEndpoints.getByUser(userId),
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = extractObject(response.data);
      return PagedResult.fromJson(data, (item) => parseJson(item as Map<String, dynamic>));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        return PagedResult(
          result: const [],
          totalCount: 0,
          page: 1,
          pageSize: 10,
        );
      }
      throw Exception(extractErrorMessage(e, 'Greška pri dohvaćanju korisničkih tendera'));
    }
  }

  Future<bool> toggleBookmark(int tenderId) async {
    try {
      final response = await dio.post(TenderApiEndpoints.toggleBookmark(tenderId));
      final data = extractData(response.data);
      return data is bool ? data : false;
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri izmjeni bookmark-a'));
    }
  }

  /// Dohvat sačuvanih (bookmarked) tendera
  Future<PagedResult<TenderDto>> getBookmarked({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await dio.get(
        TenderApiEndpoints.getBookmarks,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = extractObject(response.data);
      return PagedResult.fromJson(data, (item) => parseJson(item as Map<String, dynamic>));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri učitavanju bookmark-ovanih tendera'));
    }
  }
}