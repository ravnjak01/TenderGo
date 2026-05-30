class CategoryApiEndpoints {
  static const String baseUrl = 'category';

  static const String getAll = baseUrl;

  static  String delete(int id) => '$baseUrl/$id';

  static String update(int id) => '$baseUrl/$id';

  static String activate(int id) => '$baseUrl/$id/activate';

    static const String insert = baseUrl;




}
