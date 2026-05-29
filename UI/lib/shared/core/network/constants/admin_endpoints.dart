class AdminEndpoints {
  static const String getAllUsers = '/admin/users';

  static String banUser(String userId) => '/admin/users/$userId/ban';

  static String unbanUser(String userId) => '/admin/users/$userId/unban';

}