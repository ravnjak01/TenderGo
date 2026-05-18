// lib/shared/core/utils/user_helper.dart

class UserHelper {
  static String generateInitials({
    required String firstName,
    required String lastName,
    required String username,
  }) {
    String res = "";
    if (firstName.trim().isNotEmpty) res += firstName.trim()[0];
    if (lastName.trim().isNotEmpty) res += lastName.trim()[0];
    if (res.isNotEmpty) return res.toUpperCase();
    if (username.trim().isNotEmpty) return username.trim()[0].toUpperCase();
    return '?';
  }
}