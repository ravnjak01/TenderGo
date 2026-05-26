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

  Future<Uint8List?> fetchUserTendersReport(String userId) async {
    try {
      print("!!! PDF SERVICE POKRENUT ZA USER IZVJEŠTAJ (ID: $userId) !!!");
      final dio = DioClient.getDio();
      
      // Pozivamo novi endpoint na backendu: api/Pdf/user/{userId}/tenders
      final response = await dio.get(
         ApiEndpoints.adminReport(userId),
        options: Options(
          // 🌟 KLJUČNO: Ponovo tražimo bajtove jer backend vraća generisani PDF fajl
          responseType: ResponseType.bytes, 
        ),
      );

      if (response.statusCode == 200) {
        // Pretvaramo List<int> koji je Dio vratio u Uint8List potreban za PDF viewer
        return Uint8List.fromList(response.data);
      }
      
      return null;
    } on DioException catch (e) {
      print("Dio greška pri preuzimanju izvještaja korisnika: ${e.message}");
      if (e.response != null) {
        print("Status kod: ${e.response?.statusCode}");
        // 💡 Ako ti backend baci 403 Forbidden (jer korisnik nije Admin), ovdje će se ispisati
        print("Poruka sa servera: ${e.response?.data}"); 
      }
      return null;
    } catch (e) {
      print("Neočekivana greška kod korisničkog izvještaja: $e");
      return null;
    }
  }

}