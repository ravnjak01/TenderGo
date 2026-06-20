class AdminEndpoints {
  static const String getAllUsers = '/admin/users';
  static const String getAllTenders = '/admin/tenders';

  static String banUser(String userId) => '/admin/users/$userId/ban';

  static String unbanUser(String userId) => '/admin/users/$userId/unban';

  static String recentActivity = '/admin/dashboard/recent-activities';

}