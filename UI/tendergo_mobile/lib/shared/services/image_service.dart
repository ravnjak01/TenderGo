import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/multiple_endpoints.dart';
import 'package:tendergo/shared/models/dto/tender_image_dto.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class ImageService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  ImageService(this._dio);

  Future<String?> _getToken() async => _storage.read(key: 'jwt_token');

  Future<TenderImageDto> uploadFile(PlatformFile file) async {
    final MultipartFile multipartFile;
    if (file.path != null && file.path!.isNotEmpty) {
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    } else if (file.bytes != null && file.bytes!.isNotEmpty) {
      multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else {
      throw Exception('File "${file.name}" has no readable data.');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    try {
      final token = await _getToken();
      final response = await _dio.post(
        ApiEndpoints.uploadImage,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      final innerData = ResponseParser.object(response.data);
      return TenderImageDto.fromJson(innerData);
    } on DioException catch (e) {
      final errorMessage = ResponseParser.errorMessage(
        e,
        'Error uploading image "${file.name}"',
      );
      throw Exception(errorMessage);
    }
  }

  // POJAŠNJENJE: Pošto backend trenutno NE prima tenderId kroz upload metodu,
  // ova metoda samo prosleđuje fajl. Ako ti je tenderId neophodan na BE, 
  // moraš prvo promijeniti parametre u .NET ImagesController-u!
  // Promijenjeno u Future<TenderImageDto>
  Future<TenderImageDto> uploadForTender(int tenderId, PlatformFile file) {
    return uploadFile(file);
  }

  // Promijenjeno u Future<List<TenderImageDto>>
  Future<List<TenderImageDto>> uploadAll(List<PlatformFile> files) async {
    final results = <TenderImageDto>[]; // Lista sada prima objekte, ne stringove
    final errors = <String>[];

    for (final file in files) {
      try {
        final dto = await uploadFile(file);
        results.add(dto);
      } catch (e) {
        errors.add(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    if (results.isEmpty && errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }

    return results;
  }

  // Ne zaboravi prepraviti i uploadAllForTender ako je koristiš:
  Future<List<TenderImageDto>> uploadAllForTender(
    int tenderId,
    List<PlatformFile> files,
  ) async {
    return uploadAll(files);
  }
}
