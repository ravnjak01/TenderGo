class LocationEndpoints {
  static const String baseUrl = 'location';

  static const String getAll = '$baseUrl/all';

  static String delete(int id) => '$baseUrl/$id';

  static String update(int id) => '$baseUrl/$id';

  static String activate(int id) => '$baseUrl/$id/activate';
static String search(String searchTerm, {int page = 1, int pageSize = 10}) => 
    '$baseUrl/search?SearchTerm=$searchTerm&page=$page&pageSize=$pageSize';
  static const String insert = baseUrl;

  static String locationStatistics = '$baseUrl/statistics';
  static String locationOverview = '$baseUrl/overview';

}
