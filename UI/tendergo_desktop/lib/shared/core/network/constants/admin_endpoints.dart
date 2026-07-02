class AdminEndpoints {
  static const String dashboard = '/admin/dashboard';

  // Postojeće rute
  static const String getAllUsers = '/admin/users';
  static const String getAllTenders = '/admin/tenders';
  static const String recentActivity = '/admin/dashboard/recent-activities';

  static const String searchUsers = '/admin/users/search';

  static String banUser(String userId) => '/admin/users/$userId/ban';

  static String unbanUser(String userId) => '/admin/users/$userId/unban';

  static String adminResetPassword(String userId) => '/admin/users/$userId/reset-password';
}
