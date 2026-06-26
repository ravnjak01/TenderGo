import 'package:tendergo/shared/models/dto/tender_dto.dart';

class TenderApiEndpoints {
  static const String _tenderBase = 'tender';

  // ===== BASE CONTROLLER =====

  /// GET /api/tender
  static const String getAll = _tenderBase;

  /// GET /api/tender/{id}
  static String getById(int id) => '$_tenderBase/$id';


  /// DELETE /api/tender/{id}
  static String delete(int id) => '$_tenderBase/$id';




  /// PATCH /api/tender/{id}/cancel
  static String cancel(int id) => '$_tenderBase/$id/cancel';


  static String search(String query) => '$_tenderBase/search?SearchTerm=${Uri.encodeComponent(query)}';

 
}