import 'package:dio/dio.dart';

class BidErrorHandler {
  static bool isDuplicateBidError(DioException e, String message) {
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