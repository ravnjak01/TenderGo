import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class PdfService {
  // Prilagodi URL bazi tvog API-ja (Pazi: Ako testiraš na Android emulatoru, koristi 10.0.2.2 umjesto localhost)

  Future<Uint8List?> fetchOfferPdf(int offerId) async {
    try {
      final dio = DioClient.getDio();
      
      // 2. Pozivamo endpoint
      final response = await dio.get(
        ApiEndpoints.downloadPdf(offerId),
        options: Options(
          // 🌟 KLJUČNO: Govorimo Diu da očekujemo binarne podatke (bajtove), a ne JSON
          responseType: ResponseType.bytes, 
        ),
      );

      if (response.statusCode == 200) {
        // Dio automatski u response.data smješta List<int> kada je postavljen ResponseType.bytes
        return Uint8List.fromList(response.data);
      }
      
      return null;
    } on DioException catch (e) {
      // Dio ima odličan error handling
      if (e.response != null) {
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  

}