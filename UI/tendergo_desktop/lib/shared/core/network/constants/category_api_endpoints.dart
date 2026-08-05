class CategoryApiEndpoints {
  static const String baseUrl = 'category';

  /// GET /api/category (Paginirana lista)
  static const String getAll = baseUrl;

  /// GET /api/category/{id}
  static String getById(int id) => '$baseUrl/$id';

  /// POST /api/category
  static const String insert = baseUrl;

  /// PUT /api/category/{id}
  static String update(int id) => '$baseUrl/$id';

  /// DELETE /api/category/{id}
  static String delete(int id) => '$baseUrl/$id';

  /// PATCH ili PUT /api/category/{id}/activate
  static String activate(int id) => '$baseUrl/$id/activate';

  /// PATCH ili PUT /api/category/{id}/deactivate
  static String deactivate(int id) => '$baseUrl/$id/deactivate';

  /// GET /api/category/statistics
  static const String statistics = '$baseUrl/statistics';
}