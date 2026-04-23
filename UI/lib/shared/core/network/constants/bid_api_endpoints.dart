class BidApiEndpoints {
  static const String _bidBase = 'bid';

  // Osnovne rute
  static const String getAll = _bidBase;
  static const String insert = _bidBase;
  
  static String getById(int id) => '$_bidBase/$id';
  static String update(int id) => '$_bidBase/$id';
  static String delete(int id) => '$_bidBase/$id';

  static String withdraw(int id) => '$_bidBase/$id/withdraw';
  static String getByTender(int tenderId) => '$_bidBase/tender/$tenderId';
  static String getAllowedActions(int id) => '$_bidBase/$id/allowed-actions';
}