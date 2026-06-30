import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tendergo/shared/core/network/constants/multiple_endpoints.dart';
import 'package:tendergo/shared/models/dto/tender_image_dto.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class ImageService {
  final Dio _dio;

  ImageService(this._dio);

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
      final response = await _dio.post(
        ApiEndpoints.uploadImage,
        data: formData,
        
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

  
  Future<TenderImageDto> uploadForTender(int tenderId, PlatformFile file) {
    return uploadFile(file);
  }

  Future<List<TenderImageDto>> uploadAll(List<PlatformFile> files) async {
    final results = <TenderImageDto>[]; 
    final errors = <String>[];

    for (final file in files) {
      try {
        final dto = await uploadFile(file);
        results.add(dto);
      } catch (e) {
        errors.add(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    if (errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }

    return results;
  }


}
