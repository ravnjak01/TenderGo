import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/user_endpoints.dart';
import 'package:tendergo/shared/models/dto/review_dto.dart';
import 'package:tendergo/shared/models/dto/user_public_dto.dart';
import 'package:tendergo/shared/models/requests/rate_user_request.dart';
import 'package:tendergo/shared/models/requests/update_profile_request.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class UserService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  UserService(this._dio);

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Options> _options() async {
    final token = await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Options(headers: headers);
  }

  // Pomoćna metoda za bezbjedno odmotavanje uspješnog odgovora iz koverte
  T _unwrapEnvelope<T>(Response response, T Function(dynamic data) mapper) {
    return mapper(ResponseParser.data(response.data));
  }

  // Centralizovano čitanje grešaka iz ApiErrorEnvelope
  Exception _handleError(DioException e, String defaultMessage) {
    return Exception(ResponseParser.errorMessage(e, defaultMessage));
  }

  // ==================== API METODE ====================

  Future<UserPublicDto> getUser(String userId) async {
    try {
      final response = await _dio.get(
        UserEndpoints.getById(userId),
        options: await _options(),
      );

      return _unwrapEnvelope(response, (data) {
        if (data == null) throw Exception('Korisnički podaci nisu pronađeni.');
        return UserPublicDto.fromJson(data as Map<String, dynamic>);
      });
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju profila korisnika');
    }
  }

  Future<void> rateUser(RateUserRequest request) async {
    try {
      await _dio.post(
        UserEndpoints.rate,
        data: request.toJson(),
        options: await _options(),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri spašavanju ocjene');
    }
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    try {
      await _dio.put(
        UserEndpoints.updateProfile,
        data: request.toJson(),
        options: await _options(),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri ažuriranju profila');
    }
  }

  Future<List<ReviewDto>> getUserReviews(String userId) async {
    try {
      final response = await _dio.get(
        UserEndpoints.getReviews(userId),
        options: await _options(),
      );

      return ResponseParser.dtoList(response.data, ReviewDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju recenzija');
    }
  }
}
