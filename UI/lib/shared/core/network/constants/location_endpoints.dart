class LocationEndpoints {
  static const String baseUrl = 'location';

  static const String getAll = '$baseUrl/all';

  static  String delete(int id) => '$baseUrl/$id';

  static String update(int id) => '$baseUrl/$id';

    static const String insert = baseUrl;




}