import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class PdfService {
  // Prilagodi URL bazi tvog API-ja (Pazi: Ako testiraš na Android emulatoru, koristi 10.0.2.2 umjesto localhost)

  Future<Uint8List?> fetchOfferPdf(int offerId) async {
    try {
      print("!!! PDF SERVICE JE POKRENUT ZA ID: $offerId !!!");
      // 1. Dobijamo potpuno konfigurisan Dio instancu (sa tvojim presretačima i baznim URL-om)
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
      print("Dio greška pri preuzimanju PDF-a: ${e.message}");
      if (e.response != null) {
        print("Status kod: ${e.response?.statusCode}");
      }
      return null;
    } catch (e) {
      print("Neočekivana greška: $e");
      return null;
    }
  }
}