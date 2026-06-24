class LocationEndpoints {
  static const String baseUrl = 'location';

  static const String getAll = '$baseUrl/all';

  static String delete(int id) => '$baseUrl/$id';

  static String update(int id) => '$baseUrl/$id';

  static String activate(int id) => '$baseUrl/$id/activate';

  static String deactivate(int id) => '$baseUrl/$id/deactivate';

static String search({String? searchTerm, bool? isActive, int page = 1, int pageSize = 10}) {
  var url = '$baseUrl/admin-search?page=$page&pageSize=$pageSize';
  if (searchTerm != null && searchTerm.isNotEmpty) {
    url += '&SearchTerm=$searchTerm';
  }
  if (isActive != null) {
    url += '&IsActive=$isActive';
  }
  return url;
}
  static const String insert = baseUrl;

  static String locationStatistics = '$baseUrl/statistics';
  static String locationOverview = '$baseUrl/overview';

}
