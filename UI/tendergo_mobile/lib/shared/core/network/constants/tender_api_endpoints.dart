import 'package:tendergo/shared/models/dto/tender_dto.dart';

class TenderApiEndpoints {
  static const String _tenderBase = 'tender';



  static const String getAll = _tenderBase;

  static String getById(int id) => '$_tenderBase/$id';

  static const String insert = _tenderBase;



  static String delete(int id) => '$_tenderBase/$id';


  static const String getActive = '$_tenderBase/active';

 

  static String getByCategory(int id) => '$_tenderBase/category/$id';

  static String getByUser(String userId) => '$_tenderBase/user/$userId';



  static String cancel(int id) => '$_tenderBase/$id/cancel';

  static String award(TenderDto tender, int bidId) =>
      '$_tenderBase/${tender.id}/award/$bidId';

  static String search(String query) => '$_tenderBase/search?SearchTerm=${Uri.encodeComponent(query)}';


      static String toggleBookmark(int tenderId) => '$_tenderBase/toggle/$tenderId';

      static const String getBookmarks = '$_tenderBase/bookmarked';
}