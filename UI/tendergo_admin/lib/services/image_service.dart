import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/api_endpoints.dart';

class ImageService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  ImageService(this._dio);

  Future<String?> _getToken() async => _storage.read(key: 'jwt_token');

  /// Uploads [file] and associates it with [tenderId].
  /// Returns the stored image URL/path string from the backend.
  /// Throws [Exception] on failure.
  Future<String> uploadForTender(int tenderId, PlatformFile file) async {
    final MultipartFile multipartFile;
    if (file.path != null && file.path!.isNotEmpty) {
      multipartFile =
          await MultipartFile.fromFile(file.path!, filename: file.name);
    } else if (file.bytes != null && file.bytes!.isNotEmpty) {
      multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else {
      throw Exception('File "${file.name}" has no readable data.');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      'tenderId': tenderId,
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
      throw Exception(e.response?.data ?? 'Error uploading image "${file.name}"');
    }
  }

  /// Uploads all [files] for [tenderId], returning paths for successfully
  /// uploaded files. Errors per file are collected and rethrown as a single
  /// exception only if every upload fails; partial success is allowed.
  Future<List<String>> uploadAllForTender(
    int tenderId,
    List<PlatformFile> files,
  ) async {
    final results = <String>[];
    final errors = <String>[];

    for (final file in files) {
      try {
        final path = await uploadForTender(tenderId, file);
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
