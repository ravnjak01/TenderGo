import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';

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

	Future<UserPublicDto> getUser(String userId) async {
		try {
			final response = await _dio.get(
				'users/$userId',
				options: await _options(),
			);

			final data = response.data;
			final payload = data is Map<String, dynamic>
					? (data['result'] is Map<String, dynamic>
								? data['result'] as Map<String, dynamic>
								: data['data'] is Map<String, dynamic>
								? data['data'] as Map<String, dynamic>
								: data)
					: null;

			if (payload == null) {
				throw Exception('Invalid user payload.');
			}

			return UserPublicDto.fromJson(payload);
		} on DioException catch (e) {
			throw Exception(e.response?.data ?? 'Error fetching user');
		}
	}
}