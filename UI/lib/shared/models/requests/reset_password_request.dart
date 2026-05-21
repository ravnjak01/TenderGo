class ResetPasswordRequest {
  final String email;
  final String token;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'token': token, 'newPassword': newPassword};
  }
}
