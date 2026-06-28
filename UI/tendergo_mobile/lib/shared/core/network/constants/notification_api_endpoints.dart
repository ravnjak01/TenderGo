class NotificationApiEndpoints {
  static const String _base = 'notification';

  static const String getMy = '$_base/my';

  static String markAsRead(int id) => '$_base/$id/read';

  static const String markAllAsRead = '$_base/read-all';

  static String delete(int id) => '$_base/$id';
}
