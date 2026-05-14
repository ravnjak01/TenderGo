class NotificationApiEndpoints {
  static const String _base = 'notification';

  /// GET  /api/notification/my
  static const String getMy = '$_base/my';

  /// PATCH /api/notification/{id}/read
  static String markAsRead(int id) => '$_base/$id/read';

  /// PATCH /api/notification/read-all
  static const String markAllAsRead = '$_base/read-all';

  /// DELETE /api/notification/{id}
  static String delete(int id) => '$_base/$id';
}
