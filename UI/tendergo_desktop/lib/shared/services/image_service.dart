import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';

class ImageService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  ImageService(this._dio);

  Future<String?> _getToken() async => _storage.read(key: 'jwt_token');

  Future<String> uploadFile(PlatformFile file, {int? tenderId}) async {
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

    final payload = <String, dynamic>{'file': multipartFile};
    if (tenderId != null) {
      payload['tenderId'] = tenderId;
      payload['TenderId'] = tenderId;
      payload['tenderID'] = tenderId;
    }
    final formData = FormData.fromMap(payload);

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

      final data = response.data;
      if (data is String && data.trim().isNotEmpty) return data.trim();
      if (data is Map<String, dynamic>) {
        final url =
            data['url'] ??
            data['imageUrl'] ??
            data['path'] ??
            data['filePath'] ??
            data['result'];
        if (url != null) return url.toString();
      }
      throw Exception('Unexpected response from image upload.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data ?? 'Error uploading image "${file.name}"',
      );
    }
  }

  Future<String> uploadForTender(int tenderId, PlatformFile file) {
    return uploadFile(file, tenderId: tenderId);
  }

  Future<List<String>> uploadAll(List<PlatformFile> files) async {
    final results = <String>[];
    final errors = <String>[];

    for (final file in files) {
      try {
        final path = await uploadFile(file);
        results.add(path);
      } catch (e) {
        errors.add(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    if (results.isEmpty && errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }

    return results;
  }

  Future<List<String>> uploadAllForTender(
    int tenderId,
    List<PlatformFile> files,
  ) async {
    final results = <String>[];
    final errors = <String>[];

    for (final file in files) {
      try {
        final path = await uploadFile(file, tenderId: tenderId);
        results.add(path);
      } catch (e) {
        errors.add(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    if (results.isEmpty && errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }

    return results;
  }
}
