import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/error/api_error_handler.dart';
import 'package:tendergo_admin/core/error/bid_error_handler.dart';
import 'package:tendergo_admin/core/network/constants/bid_api_endpoints.dart';
import 'package:tendergo_admin/models/dto/bid_dto.dart';

class BidService {
	final Dio _dio;
	static const _storage = FlutterSecureStorage();

	BidService(this._dio);

	Future<String?> _getToken() async {
		return await _storage.read(key: 'jwt_token');
	}

	Future<Options> _options() async {
		final token = await _getToken();

		return Options(
			headers: {
				'Authorization': 'Bearer $token',
				'Content-Type': 'application/json',
			},
		);
	}




	// ===== GET ALL =====
	Future<List<BidDto>> getAll({int page = 1, int pageSize = 10}) async {
		try {
			final response = await _dio.get(
				BidApiEndpoints.getAll,
				queryParameters: {
					'page': page,
					'pageSize': pageSize,
				},
				options: await _options(),
			);

			return BidDto.parseBidList(response.data);
		} on DioException catch (e) {
			final message = ApiErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error fetching bids';
			if (BidErrorHandler.isDuplicateBidError(e, message)) {
        throw BidAlreadyExistsException(message: message);
      }
      throw BidServiceException(
        message: message,
        statusCode: e.response?.statusCode,
      );
		}
	}

	// ===== GET BY ID =====
	Future<BidDto> getById(int id) async {
		try {
			final response = await _dio.get(
				BidApiEndpoints.getById(id),
				options: await _options(),
			);

			return BidDto.parseBid(response.data);
		} on DioException catch (e) {
			final message = ApiErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error fetching bid';
			if (BidErrorHandler.isDuplicateBidError(e, message)) {
        throw BidAlreadyExistsException(message: message);
      }
			throw BidServiceException(
				message: message,
				statusCode: e.response?.statusCode,
			);
		}
	}

	// ===== CREATE =====
	Future<BidDto> create(BidInsertRequest data) async {
  try {
    final response = await _dio.post(
      BidApiEndpoints.insert,
      data: data.toJson(),
      options: await _options(),
    );

    return BidDto.parseBid(response.data);
  } on DioException catch (e) {
    final message = ApiErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error creating bid';

    // Logika za specifične izuzetke
    if (BidErrorHandler.isDuplicateBidError(e, message)) {
      throw BidAlreadyExistsException(message: message);
    }

    throw BidServiceException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}



	// ===== UPDATE =====
	Future<bool> update(int id, Map<String, dynamic> data) async {
		try {
			final response = await _dio.patch(
				BidApiEndpoints.update(id),
				data: data,
				options: await _options(),
			);

			return response.statusCode! >= 200 && response.statusCode! < 300;
		} on DioException catch (e) {
			return false;
		}
	}

	// ===== DELETE =====
	Future<bool> delete(int id) async {
		try {
			final response = await _dio.delete(
				BidApiEndpoints.delete(id),
				options: await _options(),
			);

			return response.statusCode! >= 200 && response.statusCode! < 300;
		} on DioException catch (e) {
			return false;
		}
	}

	// ===== WITHDRAW =====
	Future<dynamic> withdraw(int id) async {
		try {
			final response = await _dio.patch(
				BidApiEndpoints.withdraw(id),
				options: await _options(),
			);

			return response.data;
		} on DioException catch (e) {
			throw Exception(e.response?.data ?? 'Error withdrawing bid');
		}
	}

//dosao do prikazavinja ponuda po tendera,radi prikazuje se ,sljedece dodati dugme 
//biranja ponude
	// ===== BY TENDER =====
	Future<List<BidDto>> getByTender(int tenderId) async {
		try {
			final response = await _dio.get(
				BidApiEndpoints.getByTender(tenderId),
				options: await _options(),
			);
     if (response.data == null) return [];
			return BidDto.parseBidList(response.data);
		} on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      if (e.response?.statusCode == 403) {
        throw Exception(
          'You are not allowed to view bids for this tender.',
        );
      }
			throw Exception(e.response?.data ?? 'Error fetching bids by tender');
		}
	}

	// ===== ALLOWED ACTIONS =====
	Future<List<dynamic>> getAllowedActions(int id) async {
		try {
			final response = await _dio.get(
				BidApiEndpoints.getAllowedActions(id),
				options: await _options(),
			);

			return List<dynamic>.from(response.data);
		} on DioException catch (e) {
			throw Exception(e.response?.data ?? 'Error fetching bid actions');
		}
	}
}

