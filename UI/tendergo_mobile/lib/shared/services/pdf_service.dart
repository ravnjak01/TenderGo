import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class PdfService {
  Future<Uint8List?> fetchOfferPdf(int offerId) async {
    try {
      final dio = DioClient.getDio();

      final response = await dio.get(
        ApiEndpoints.downloadPdf(offerId),
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }

      return null;
    } on DioException catch (e) {
      if (e.response != null) {}
      return null;
    } catch (e) {
      return null;
    }
  }
}
