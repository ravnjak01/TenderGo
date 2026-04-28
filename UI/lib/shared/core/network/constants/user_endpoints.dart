class UserEndpoints {
  static const String _userBase = 'users';
  
  static String getById(String id) => '$_userBase/$id';
  static const String rate = '$_userBase/rate';
  static const String updateProfile = '$_userBase/profile'; // Naš novi endpoint
}