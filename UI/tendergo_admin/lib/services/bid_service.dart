import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

	BidDto _parseBid(dynamic data) {
		if (data is Map<String, dynamic>) {
			return BidDto.fromJson(data);
		}

		throw const FormatException('Invalid bid payload format.');
	}

	List<BidDto> _parseBidList(dynamic data) {
		if (data is List) {
			return data
				.whereType<Map<String, dynamic>>()
				.map(BidDto.fromJson)
				.toList();
		}

		if (data is Map<String, dynamic>) {
			final dynamic listLike = data['items'] ?? data['data'] ?? data['results'];
			if (listLike is List) {
				return listLike
					.whereType<Map<String, dynamic>>()
					.map(BidDto.fromJson)
					.toList();
			}
		}

		throw const FormatException('Invalid bids payload format.');
	}

	String? _extractErrorMessage(dynamic data) {
  if (data == null) return null;

  try {
    // Tvoj backend šalje: {"errors": {"UserError": ["Poruka"], "ERROR": ["Poruka"]}}
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
      var errors = data['errors'] as Map<String, dynamic>;

      if (errors.isNotEmpty) {
        // Uzimamo prvu listu grešaka (npr. UserError ili ERROR)
        var firstKey = errors.keys.first;
        var errorList = errors[firstKey] as List<dynamic>;

        if (errorList.isNotEmpty) {
          return errorList.first.toString();
        }
      }
    }
    
    // Fallback ako je format drugačiji (npr. direktna poruka)
    if (data is Map && data.containsKey('message')) {
      return data['message'];
    }
  } catch (e) {
    print("Greška pri parsiranju error poruke: $e");
  }

  return null;
}
bool _isDuplicateBidError(DioException e, String message) {
  // Provjera preko sadržaja poruke koju smo dobili od UserException-a
  final duplicatePhrases = [
    'already sent a bid',
    'već ste poslali ponudu',
    'bid already exists'
  ];

  bool containsPhrase = duplicatePhrases.any(
    (phrase) => message.toLowerCase().contains(phrase.toLowerCase())
  );

  // Provjera preko status koda (ErrorFilter šalje 400 za UserException)
  return e.response?.statusCode == 400 && containsPhrase;
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

			return _parseBidList(response.data);
		} on DioException catch (e) {
			final message = _extractErrorMessage(e.response?.data) ?? 'Error fetching bids';
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

			return _parseBid(response.data);
		} on DioException catch (e) {
			final message = _extractErrorMessage(e.response?.data) ?? 'Error fetching bid';
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

    return _parseBid(response.data);
  } on DioException catch (e) {
    // Ovde izvlačimo tačnu poruku sa servera
    final message = _extractErrorMessage(e.response?.data) ?? 'Error creating bid';

    // Logika za specifične izuzetke
    if (_isDuplicateBidError(e, message)) {
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

	// ===== BY TENDER =====
	Future<List<BidDto>> getByTender(int tenderId) async {
		try {
			final response = await _dio.get(
				BidApiEndpoints.getByTender(tenderId),
				options: await _options(),
			);

			return _parseBidList(response.data);
		} on DioException catch (e) {
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

class BidServiceException implements Exception {
	final String message;
	final int? statusCode;

	const BidServiceException({
		required this.message,
		this.statusCode,
	});

	@override
	String toString() => message;
}

class BidAlreadyExistsException extends BidServiceException {
	const BidAlreadyExistsException({required super.message});
}