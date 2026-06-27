class CategoryApiEndpoints {
  static const String baseUrl = 'category';

  static const String getAll = baseUrl;

  static  String delete(int id) => '$baseUrl/$id';

  static String update(int id) => '$baseUrl/$id';

  static String activate(int id) => '$baseUrl/$id/activate';
  static String deactivate(int id) => '$baseUrl/$id/deactivate';


// Pazi da baseUrl završava sa /api/category ili ručno dodaj putanju
static String search(String searchTerm, {int page = 1, int pageSize = 10}) => 
    '$baseUrl/search?searchTerm=$searchTerm&page=$page&pageSize=$pageSize';

    static const String insert = baseUrl;

static String categoryStatistics = '$baseUrl/statistics';



}
