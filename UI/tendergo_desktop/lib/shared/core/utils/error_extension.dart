import 'package:dio/dio.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/services/api_helper.dart';

extension UserMessageExtension on Object {
  /// Pretvara bilo koju grešku u čistu korisničku poruku
  /// bez "Exception:" prefiksa i bez tehničkih detalja.
  String toUserMessage() {
    final error = this;

    // 1. Ako je greška spakovana u tvoj ApiResponse (npr. iz AdminService)
    if (error is ApiResponse) {
      return error.message ?? 'Došlo je do greške.';
    }

    // 2. Ako je neuhvaćena DioException (zbog mrežnih prekida i sl.)
    if (error is DioException) {
      final apiResponse = ApiHelper.handleDioError(error);
      return apiResponse.message ?? 'Greška u komunikaciji sa serverom.';
    }

    // 3. Ako je servis bacio Exception('Pročišćena poruka sa backenda')
    var message = error.toString();

    // Sređujemo Exception i FormatException prefikse
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    } else if (message.startsWith('FormatException: ')) {
      message = message.substring(17);
    }

    return message.trim();
  }
}