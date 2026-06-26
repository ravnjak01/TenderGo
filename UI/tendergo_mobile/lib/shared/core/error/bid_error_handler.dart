import 'package:dio/dio.dart';

class BidErrorHandler {
  static bool isDuplicateBidError(DioException e, String message) {
  final duplicatePhrases = [
    'already sent a bid',
    'već ste poslali ponudu',
    'bid already exists'
  ];

  bool containsPhrase = duplicatePhrases.any(
    (phrase) => message.toLowerCase().contains(phrase.toLowerCase())
  );

  return e.response?.statusCode == 400 && containsPhrase;
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