import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/error/bid_error_handler.dart';
import 'package:tendergo/shared/core/error/error_handler.dart';
import 'package:tendergo/shared/core/network/constants/bid_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/requests/bid_insert_request.dart';

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

			final rawList = response.data as List;
			return rawList
				.map((item) => BidDto.fromJson(item as Map<String, dynamic>))
				.toList();
		} on DioException catch (e) {
			final message = ErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error fetching bids';
			if (BidErrorHandler.isDuplicateBidError(e, message)) {
        throw BidAlreadyExistsException(message: message);
      }
      throw BidServiceException(
        message: message,
        statusCode: e.response?.statusCode,
      );
		}
	}

	// ===== GET BY CURRENT USER =====
	Future<List<BidDto>> getByUser(String userId, {int page = 1, int pageSize = 10}) async {
		try {
			final response = await _dio.get(
				BidApiEndpoints.getByUser(userId),
				queryParameters: {
					'page': page,
					'pageSize': pageSize,
				},
				options: await _options(),
			);

			
			final rawList = response.data as List;
			return rawList
				.map((item) => BidDto.fromJson(item as Map<String, dynamic>))
				.toList();
		} on DioException catch (e) {
			// Some environments may not expose a dedicated "by user" endpoint.
			if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
				final all = await getAll(page: page, pageSize: pageSize);
				return all
					.where((bid) => bid.submittedByUserId.trim() == userId.trim())
					.toList(growable: false);
			}

			final message = ErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error fetching user bids';
			if (BidErrorHandler.isDuplicateBidError(e, message)) {
				throw BidAlreadyExistsException(message: message);
			}
			throw BidServiceException(
				message: message,
				statusCode: e.response?.statusCode,
			);
		}
	}

	// ===== GET MY BIDS =====
	Future<List<BidDto>> getMyBids({int page = 1, int pageSize = 10}) async {
		try {
			final response = await _dio.get(
				BidApiEndpoints.getMyBids,
				queryParameters: {
					'page': page,
					'pageSize': pageSize,
				},
				options: await _options(),
			);

			final rawList = response.data as List;
			return rawList
				.map((item) => BidDto.fromJson(item as Map<String, dynamic>))
				.toList();
		} on DioException catch (e) {
			final message = ErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error fetching current user bids';
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

			return BidDto.fromJson(response.data as Map<String,dynamic>);
		} on DioException catch (e) {
			final message = ErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error fetching bid';
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
    // DODAJ OVO SAMO ZA DEBUG:
    final response = await _dio.post(
      BidApiEndpoints.insert,
      data: data.toJson(),
      options: await _options(),
    );

    return BidDto.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    final message = ErrorHandler.extractErrorMessage(e.response?.data) ?? 'Error creating bid';

    if (BidErrorHandler.isDuplicateBidError(e, message)) {
      throw BidAlreadyExistsException(message: message);
    }

    throw BidServiceException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}


	// ===== WITHDRAW =====
	Future<BidDto> withdraw(int id) async {
		try {
			final response = await _dio.patch(
				BidApiEndpoints.withdraw(id),
				options: await _options(),
			);

			return BidDto.fromJson(response.data as Map<String,dynamic>);
		} on DioException catch (e) {
			throw Exception(e.response?.data ?? 'Error withdrawing bid');
		}
	}

	// ===== BY TENDER =====
	Future<List<BidDto>> getByTender(int tenderId) async {
  try {
    final response = await _dio.get(
      BidApiEndpoints.getByTender(tenderId),
      options: await _options(),
    );

    if (response.data == null) return [];

    final rawList = response.data as List;

    return rawList
        .map((jsonItem) => BidDto.fromJson(jsonItem as Map<String, dynamic>))
        .toList();

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

    Future<BidDto> cancel(int id) async {
    try {
      final response = await _dio.put(
        BidApiEndpoints.cancel(id),
        options: await _options(),
      );

      return BidDto.fromJson(response.data as Map<String,dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error canceling tender');
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

