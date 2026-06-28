import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/user_endpoints.dart';
import 'package:tendergo/shared/models/dto/review_dto.dart';
import 'package:tendergo/shared/models/dto/user_public_dto.dart';
import 'package:tendergo/shared/models/requests/change_password_request.dart';
import 'package:tendergo/shared/models/requests/rate_user_request.dart';
import 'package:tendergo/shared/models/requests/update_profile_request.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

  T _unwrapEnvelope<T>(Response response, T Function(dynamic data) mapper) {
    return mapper(ResponseParser.data(response.data));
  }

  Exception _handleError(DioException e, String defaultMessage) {
    return Exception(ResponseParser.errorMessage(e, defaultMessage));
  }
  Future<void> changePassword(ChangePasswordRequest request) async {
  try {
    await _dio.post(
      UserEndpoints.changePassword,
      data: request.toJson(),
    );
  } on DioException catch (e) {
    throw _handleError(e, 'Greška pri promjeni lozinke');
  }
}


  Future<UserPublicDto> getUser(String userId) async {
    try {
      final response = await _dio.get(UserEndpoints.getById(userId));

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
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri ažuriranju profila');
    }
  }

  Future<List<ReviewDto>> getUserReviews(String userId) async {
    try {
      final response = await _dio.get(UserEndpoints.getReviews(userId));

      return ResponseParser.dtoList(response.data, ReviewDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju recenzija');
    }
  }
}
