import 'package:tendergo/shared/models/dto/tender_dto.dart';

class TenderApiEndpoints {
  static const String _tenderBase = 'tender';

  // ===== BASE CONTROLLER =====

  /// GET /api/tender
  static const String getAll = _tenderBase;

  /// GET /api/tender/{id}
  static String getById(int id) => '$_tenderBase/$id';

  /// POST /api/tender
  static const String insert = _tenderBase;

  /// PATCH /api/tender/{id}
  static String update(int id) => '$_tenderBase/$id';

  /// DELETE /api/tender/{id}
  static String delete(int id) => '$_tenderBase/$id';

  // ===== CUSTOM ENDPOINTS =====

  /// GET /api/tender/active
  static const String getActive = '$_tenderBase/active';

  /// GET /api/tender/closed
  static const String getClosed = '$_tenderBase/closed';

  static const String getCancelled = '$_tenderBase/cancelled';

  /// GET /api/tender/category/{id}
  static String getByCategory(int id) => '$_tenderBase/category/$id';

  /// GET /api/tender/user/{userId}
  static String getByUser(String userId) => '$_tenderBase/user/$userId';



  /// PATCH /api/tender/{id}/cancel
  static String cancel(int id) => '$_tenderBase/$id/cancel';

  /// PATCH /api/tender/{id}/award/{bidId}
  static String award(TenderDto tender, int bidId) =>
      '$_tenderBase/${tender.id}/award/$bidId';

  static String search(String query) => '$_tenderBase/search?SearchTerm=${Uri.encodeComponent(query)}';

  /// GET /api/tender/{id}/allowedActions
  static String allowedActions(int id) =>
      '$_tenderBase/$id/allowedActions';

      static String toggleBookmark(int tenderId) => '$_tenderBase/toggle/$tenderId';

      static const String getBookmarks = '$_tenderBase/bookmarked';
}