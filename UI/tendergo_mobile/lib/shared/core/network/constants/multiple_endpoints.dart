class ApiEndpoints {
  // --- AUTH MODUL ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static const String  me = '/auth/me';

  static String uploadImage='images/upload';
  static String deleteImage='images';

  // --- RECOMMENDATIONS ---
  static String recommendSimilar(int tenderId) => '/recommend/similar/$tenderId';
  static const String recommendForUser = '/recommend/for-user';

  static const String refreshToken = '/auth/refresh-token';

  // USER ACTIVITY
  static const String userActivity='/user-activities/log';
}
