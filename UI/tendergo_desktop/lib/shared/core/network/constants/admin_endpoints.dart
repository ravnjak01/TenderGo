class AdminEndpoints {
  static const String dashboard = '/admin/dashboard';

  // Postojeće rute
  static const String getAllUsers = '/admin/users';
  static const String getAllTenders = '/admin/tenders';
  static const String recentActivity = '/admin/dashboard/recent-activities';

  // Dodata ruta za pretragu korisnika (koristi query parametre pri pozivu)
  static const String searchUsers = '/admin/users/search';

  static String banUser(String userId) => '/admin/users/$userId/ban';

  static String unbanUser(String userId) => '/admin/users/$userId/unban';

  // Dodata ruta za resetovanje lozinke od strane admina
  static String adminResetPassword(String userId) => '/admin/users/$userId/reset-password';
}
