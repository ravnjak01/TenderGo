class AdminUserEndpoints {
  static const baseUrl = '/admin/users';
  static const getAllUsers = '$baseUrl';
  static String banUser(String userId) => '$baseUrl/$userId/ban';
  static String unbanUser(String userId) => '$baseUrl/$userId/unban';
  static String adminResetPassword(String userId) => '$baseUrl/$userId/reset-password';
  static const searchUsers = '$baseUrl/search';
}