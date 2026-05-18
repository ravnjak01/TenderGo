class ApiEndpoints {
  // --- AUTH MODUL ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  // --- KORISNIK ---

  static const String  me = '/auth/me';


  //IMAGES

  static String uploadImage='Images/upload';
  static String deleteImage='Images';

  // --- RECOMMENDATIONS ---
  static const String recommendSimilar = '/recommend/similar';
  static const String recommendForUser = '/recommend/for-user';


  static const String refreshToken = '/auth/refresh-token';
}