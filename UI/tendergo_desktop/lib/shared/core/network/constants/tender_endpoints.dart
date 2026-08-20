class TenderApiEndpoints {
  static const String baseUrl = 'tender';

  /// GET /api/tender 
  static const String getAll = baseUrl;

  /// GET /api/tender/{id}
  static String getById(int id) => '$baseUrl/$id';

  /// POST /api/tender
  static const String insert = baseUrl;

  /// PUT /api/tender/{id}
  static String update(int id) => '$baseUrl/$id';

  /// DELETE /api/tender/{id}
  static String delete(int id) => '$baseUrl/$id';

  /// PUT/PATCH /api/tender/{id}/cancel
  static String cancel(int id) => '$baseUrl/$id/cancel';

  /// GET /api/tender/admin 
  static const String adminSearch = '$baseUrl/admin';
}