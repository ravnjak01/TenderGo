class LocationEndpoints {
  static const String baseUrl = 'location';

  /// GET /api/location 
  static const String getPaged = baseUrl;

  /// GET /api/location/all 
  static const String getAllFlat = '$baseUrl/all';

  /// GET /api/location/{id}
  static String getById(int id) => '$baseUrl/$id';

  /// POST /api/location
  static const String insert = baseUrl;

  /// PATCH /api/location/{id}
  static String update(int id) => '$baseUrl/$id';

  /// DELETE /api/location/{id}
  static String delete(int id) => '$baseUrl/$id';

  /// PATCH  /api/location/{id}/activate
  static String activate(int id) => '$baseUrl/$id/activate';

  /// PATCH  /api/location/{id}/deactivate
  static String deactivate(int id) => '$baseUrl/$id/deactivate';

  /// Custom statistike 
  static const String statistics = '$baseUrl/statistics';
  static const String overview = '$baseUrl/overview';
}